/// <reference types="@deno" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

import {
  ANDROID_PACKAGE,
  ALLOWED_PRODUCTS,
  SubscriptionState,
  isEntitled,
  json,
  adminClient,
  saveSubscription,
  HttpError,
} from "../_shared/common.ts"
import { fetchAppleSubscription, decodeJws } from "../_shared/apple.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const { signedTransaction, productId, platform } = await req.json()
    console.log(
      `[VerifyPurchase] Request received: platform=${platform}, productId=${productId}, signedTransaction length=${signedTransaction?.length ?? 0}`,
    )

    if (!signedTransaction || typeof signedTransaction !== "string") {
      throw new HttpError(400, "signedTransaction is missing or invalid")
    }
    if (!productId || typeof productId !== "string") {
      throw new HttpError(400, "productId is missing or invalid")
    }
    if (!platform || (platform !== "ios" && platform !== "android")) {
      throw new HttpError(400, "platform must be ios or android")
    }
    if (!ALLOWED_PRODUCTS.includes(productId)) {
      throw new HttpError(400, `Product not allowed: ${productId}`)
    }

    const supabaseAdmin = adminClient()

    const authHeader = req.headers.get("Authorization")
    if (!authHeader) throw new HttpError(401, "Authorization header missing")
    const token = authHeader.replace("Bearer ", "")
    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(token)
    if (userError || !user) throw new HttpError(401, "User not identified")
    const userId = user.id
    console.log(`[VerifyPurchase] User identified: ${userId}`)

    let state: SubscriptionState

    if (platform === "ios") {
      console.log("[VerifyPurchase] Processing iOS purchase")
      const jwsPayload = decodeJws(signedTransaction)
      const originalTransactionId = jwsPayload.originalTransactionId
      if (!originalTransactionId) throw new HttpError(400, "originalTransactionId missing in JWS")

      // La transaction du client indique déjà son environnement : on l'utilise
      // comme indice pour interroger le bon host Apple en premier (évite un
      // aller-retour voué à l'échec tant que Production n'a pas d'accès complet,
      // ex: Paid Applications Agreement pas encore actif).
      const envHint = jwsPayload.environment as string | undefined
      console.log(
        `[VerifyPurchase] Decoded JWS: originalTransactionId=${originalTransactionId}, environment=${envHint}`,
      )

      console.log("[VerifyPurchase] Fetching Apple subscription status")
      const { state: appleState } = await fetchAppleSubscription(originalTransactionId, envHint)
      state = appleState
      state.productId = productId
      console.log(`[VerifyPurchase] Apple subscription state: ${JSON.stringify(state)}`)
    } else {
      console.log("[VerifyPurchase] Processing Android purchase")
      const serviceAccountJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")
      if (!serviceAccountJson) throw new HttpError(500, "GOOGLE_SERVICE_ACCOUNT_JSON not configured")
      const serviceAccount = JSON.parse(serviceAccountJson)

      // @ts-ignore
      const { GoogleAuth } = await import("https://esm.sh/google-auth-library@9.0.0")
      const auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
      })
      const client = await auth.getClient()
      const accessToken = (await client.getAccessToken()).token

      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE}/purchases/subscriptions/${productId}/tokens/${signedTransaction}`
      const verifyRes = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } })
      const data = await verifyRes.json()

      if (!verifyRes.ok) {
        console.error("[VerifyPurchase] Google verification failed:", data)
        throw new HttpError(verifyRes.status, `Google error: ${data.error?.message ?? verifyRes.statusText}`)
      }

      if (data.acknowledgementState === 0) {
        const ackRes = await fetch(`${url}:acknowledge`, {
          method: "POST",
          headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
        })
        if (!ackRes.ok) console.error("[VerifyPurchase] Google acknowledge failed:", await ackRes.text())
      }

      const expiryTimeMillis = Number(data.expiryTimeMillis ?? "0")
      const paymentState = Number(data.paymentState ?? "0")
      const status: SubscriptionState["status"] =
        expiryTimeMillis > Date.now() && paymentState !== 0 ? "active" : "expired"

      state = {
        platform: "android",
        productId,
        originalTransactionId: signedTransaction, // purchase token
        status,
        expiresAt: new Date(expiryTimeMillis),
        autoRenew: data.autoRenewing ?? false,
        environment: data.regionCode ?? "production",
      }
      console.log(`[VerifyPurchase] Google subscription state: ${JSON.stringify(state)}`)
    }

    console.log("[VerifyPurchase] Saving subscription")
    const owner = await saveSubscription(supabaseAdmin, state, userId)
    if (!owner) {
      // Ne devrait pas arriver ici : userId est toujours fourni côté client authentifié.
      throw new HttpError(500, "Impossible de déterminer le propriétaire de l'abonnement")
    }
    console.log("[VerifyPurchase] Subscription saved, is_premium recalculé par le trigger SQL")

    return json({
      status: "success",
      platform: state.platform,
      productId: state.productId,
      expiresAt: state.expiresAt,
      autoRenew: state.autoRenew,
      isPremium: isEntitled(state),
    })
  } catch (err) {
    if (err instanceof HttpError) {
      console.error(`[VerifyPurchase] HttpError: ${err.status} - ${err.message}`)
      return json({ error: err.message }, err.status)
    }
    console.error("[VerifyPurchase] Unexpected error:", err)
    return json({ error: "Internal server error" }, 500)
  }
})