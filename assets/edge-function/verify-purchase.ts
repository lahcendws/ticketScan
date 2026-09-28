/// <reference types="@deno" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

import { APPLE_BUNDLE_ID, ANDROID_PACKAGE, ALLOWED_PRODUCTS, SubscriptionState, isEntitled, json, adminClient, HttpError } from "./common.ts"
import { fetchAppleSubscription, decodeJws } from "./apple.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { signedTransaction, productId, platform } = await req.json()

    if (!signedTransaction || typeof signedTransaction !== 'string') {
      throw new HttpError(400, 'signedTransaction is missing or invalid')
    }
    if (!productId || typeof productId !== 'string') {
      throw new HttpError(400, 'productId is missing or invalid')
    }
    if (!platform || (platform !== 'ios' && platform !== 'android')) {
      throw new HttpError(400, 'platform must be ios or android')
    }
    if (!ALLOWED_PRODUCTS.includes(productId)) {
      throw new HttpError(400, `Product not allowed: ${productId}`)
    }

    const supabaseAdmin = adminClient()

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new HttpError(401, 'Authorization header missing')
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    if (userError || !user) throw new HttpError(401, 'User not identified')
    const userId = user.id

    let state: SubscriptionState

    if (platform === 'ios') {
      // Decode JWS to get originalTransactionId
      const jwsPayload = decodeJws(signedTransaction)
      const originalTransactionId = jwsPayload.originalTransactionId
      if (!originalTransactionId) throw new HttpError(400, 'originalTransactionId missing in JWS')
      // Fetch subscription status from Apple
      const { state: appleState } = await fetchAppleSubscription(originalTransactionId)
      state = appleState
      // Override productId with the one from request (should match)
      state.productId = productId
    } else if (platform === 'android') {
      // Verify with Google Play Developer API
      const serviceAccountJson = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON')
      if (!serviceAccountJson) throw new HttpError(500, 'GOOGLE_SERVICE_ACCOUNT_JSON not configured')
      const serviceAccount = JSON.parse(serviceAccountJson)

      // Import google-auth-library dynamically to avoid bundling issues
      // @ts-ignore
      const { GoogleAuth } = await import('https://esm.sh/google-auth-library@9.0.0')
      const auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      })
      const client = await auth.getClient()
      const accessToken = (await client.getAccessToken()).token

      const packageName = ANDROID_PACKAGE
      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${signedTransaction}`

      const verifyRes = await fetch(url, {
        headers: { Authorization: `Bearer ${accessToken}` },
      })
      const data = await verifyRes.json()

      if (!verifyRes.ok) {
        console.error('Google verification failed:', data)
        throw new HttpError(verifyRes.status, `Google error: ${data.error?.message ?? verifyRes.statusText}`)
      }

      // Acknowledge if needed
      if (data.acknowledgementState === 0) {
        const acknowledgeRes = await fetch(`${url}:acknowledge`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
        })
        if (!acknowledgeRes.ok) {
          console.error('Google acknowledge failed:', await acknowledgeRes.text())
          // Not critical, but warn
        }
      }

      const expiryTimeMillis = Number(data.expiryTimeMillis ?? '0')
      const autoRenewing = data.autoRenewing ?? false
      const paymentState = Number(data.paymentState ?? '0')

      let status: SubscriptionState['status'] = 'expired'
      if (expiryTimeMillis > Date.now()) {
        // Consider active if payment received or pending? We'll treat paymentState >=1 as active
        if (paymentState === 1) {
          status = 'active'
        } else if (paymentState === 0) {
          // pending - treat as not active yet
          status = 'expired'
        } else {
          // free trial or upgrade
          status = 'active'
        }
      }
      // If user cancelled but still within period, we still treat as active but autoRenew false
      // autoRenewing already reflects that

      state = {
        platform: 'android',
        productId,
        originalTransactionId: signedTransaction, // purchase token
        status,
        expiresAt: new Date(expiryTimeMillis),
        autoRenew: autoRenewing,
        environment: data.regionCode ?? 'production', // approximate
      }
    } else {
      throw new HttpError(400, `Unsupported platform: ${platform}`)
    }

    // Upsert subscription
    const { error: upsertError } = await supabaseAdmin
      .from('subscriptions')
      .upsert({
        user_id: userId,
        platform: state.platform,
        product_id: state.productId,
        original_transaction_id: state.originalTransactionId,
        status: state.status,
        expires_at: state.expiresAt.toISOString(),
        auto_renew: state.autoRenew,
        environment: state.environment,
        last_verified_at: new Date().toISOString(),
      }, { onConflict: 'platform,original_transaction_id' })

    if (upsertError) throw upsertError

    // Update profile with subscription details
    const subscriptionType = state.productId.endsWith('_yearly') ? 'yearly' : 'monthly'
    const daysRemaining = Math.max(0, Math.floor((state.expiresAt.getTime() - Date.now()) / 86400000))
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({
        is_premium: isEntitled(state), // compute entitlement
        subscription_type: subscriptionType,
        subscription_expires_at: state.expiresAt.toISOString(),
        days_remaining: daysRemaining,
      })
      .eq('id', userId)

    if (profileError) throw profileError

    return json({ status: 'success', platform: state.platform, productId: state.productId, expiresAt: state.expiresAt, autoRenew: state.autoRenew })
  } catch (err) {
    if (err instanceof HttpError) {
      return json({ error: err.message }, err.status)
    }
    console.error('Unexpected error:', err)
    return json({ error: 'Internal server error' }, 500)
  }
})