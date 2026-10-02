/// <reference types="@deno" />

// Webhook App Store Server Notifications V2.
// Reçoit un événement Apple (renouvellement, échec de paiement, remboursement,
// période de grâce, annulation...) et remet à jour l'abonnement correspondant
// SANS attendre que l'utilisateur rouvre l'app.
//
// Configuration requise dans App Store Connect (App Information → App Store
// Server Notifications) : renseigner cette URL comme "Production Server URL"
// ET "Sandbox Server URL" :
//   https://<PROJECT_REF>.supabase.co/functions/v1/apple-notifications
//
// IMPORTANT : cette fonction doit être déployée avec la vérification JWT
// désactivée (Apple n'envoie pas de token Supabase) — voir supabase/config.toml.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { Buffer } from "node:buffer"
// Bibliothèque officielle Apple : gère la vérification de la chaîne de
// certificats x5c jusqu'à la racine Apple. Ne PAS remplacer par un décodage
// JWS "à la main" (decodeJws) ici : sans vérification de signature, n'importe
// qui pourrait POSTer un faux événement et activer du premium gratuitement.
import { SignedDataVerifier, Environment } from "npm:@apple/app-store-server-library@1"

import { APPLE_BUNDLE_ID, adminClient, saveSubscription, json, errMessage } from "../_shared/common.ts"
import { fetchAppleSubscription } from "../_shared/apple.ts"

// Best-effort : un souci de log ne doit jamais faire échouer le traitement
// principal ni provoquer un retry Apple inutile.
async function logNotification(entry: {
  notification_type?: string
  subtype?: string | null
  original_transaction_id?: string
  environment?: string
  processed_ok: boolean
  error_message?: string
}) {
  try {
    await adminClient().from("apple_notifications_log").insert(entry)
  } catch (err) {
    console.error("[AppleNotifications] Failed to write log entry:", errMessage(err))
  }
}

const ROOT_CA_URL = "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer"

// ------------------------------------------------------------
// Certificats racine Apple (mis en cache pour la durée de vie de l'isolate)
// ------------------------------------------------------------

let rootCertCache: Buffer[] | null = null

async function loadAppleRootCertificates(): Promise<Buffer[]> {
  if (rootCertCache) return rootCertCache
  const res = await fetch(ROOT_CA_URL)
  if (!res.ok) throw new Error(`Impossible de récupérer le certificat racine Apple: HTTP ${res.status}`)
  const cert = Buffer.from(new Uint8Array(await res.arrayBuffer()))
  rootCertCache = [cert]
  return rootCertCache
}

// ------------------------------------------------------------
// Vérificateurs (mis en cache) — un par environnement, car Apple peut
// pointer la même URL pour Sandbox et Production.
// ------------------------------------------------------------

let prodVerifier: SignedDataVerifier | null = null
let sandboxVerifier: SignedDataVerifier | null = null

async function getVerifiers(): Promise<{ prod: SignedDataVerifier; sandbox: SignedDataVerifier }> {
  if (prodVerifier && sandboxVerifier) return { prod: prodVerifier, sandbox: sandboxVerifier }

  const roots = await loadAppleRootCertificates()
  const enableOnlineChecks = true // vérifie aussi la révocation + l'expiration des certificats

  // Requis par Apple uniquement pour l'environnement Production ; laisser vide
  // avant la mise en ligne réelle de l'app (le Sandbox n'en a pas besoin).
  const appAppleIdEnv = Deno.env.get("APPLE_APP_ID")
  const appAppleId = appAppleIdEnv ? Number(appAppleIdEnv) : undefined

  prodVerifier = new SignedDataVerifier(roots as any, enableOnlineChecks, Environment.PRODUCTION, APPLE_BUNDLE_ID, appAppleId)
  sandboxVerifier = new SignedDataVerifier(roots as any, enableOnlineChecks, Environment.SANDBOX, APPLE_BUNDLE_ID)

  return { prod: prodVerifier, sandbox: sandboxVerifier }
}

/**
 * Vérifie et décode la notification, en essayant Production puis Sandbox
 * (on ne sait pas à l'avance de quel environnement vient l'appel).
 */
async function verifyNotification(signedPayload: string): Promise<any> {
  const { prod, sandbox } = await getVerifiers()

  try {
    return await prod.verifyAndDecodeNotification(signedPayload)
  } catch (prodError) {
    try {
      return await sandbox.verifyAndDecodeNotification(signedPayload)
    } catch (sandboxError) {
      throw new Error(
        `Signature de notification Apple invalide (production: ${errMessage(prodError)}; sandbox: ${errMessage(sandboxError)})`,
      )
    }
  }
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405)
  }

  let notification: any

  try {
    const body = await req.json()
    if (!body.signedPayload || typeof body.signedPayload !== "string") {
      // Apple ne renverra jamais un corps sans signedPayload en usage normal :
      // une requête ainsi malformée n'est pas légitime, on répond 400 sans retry.
      return json({ error: "signedPayload missing" }, 400)
    }

    notification = await verifyNotification(body.signedPayload)
  } catch (err) {
    // Signature invalide : ne PAS traiter, ne PAS faire confiance au contenu.
    console.error("[AppleNotifications] Signature verification failed:", errMessage(err))
    return json({ error: "Invalid signature" }, 400)
  }

  const payload = notification.payload ?? notification
  const notificationType = payload.notificationType
  const subtype = payload.subtype
  console.log(`[AppleNotifications] Received: type=${notificationType}, subtype=${subtype ?? "none"}`)

  // Notification de test envoyée depuis App Store Connect ("Request a Test
  // Notification") — rien à traiter, on accuse juste réception.
  if (notificationType === "TEST") {
    console.log("[AppleNotifications] Test notification acknowledged")
    return json({ status: "ok" })
  }

  const signedTransactionInfo = payload.data?.signedTransactionInfo
  if (!signedTransactionInfo) {
    console.log(`[AppleNotifications] Notification ${notificationType} sans signedTransactionInfo, ignorée`)
    return json({ status: "ok" })
  }

  try {
    // On extrait juste l'identifiant de la transaction depuis le payload déjà
    // vérifié, puis on redemande l'état AUTORITAIRE via la même API que
    // verify-purchase (Get All Subscription Statuses) plutôt que d'essayer de
    // ré-interpréter nous-mêmes ~15 combinaisons notificationType/subtype :
    // une seule source de vérité pour "quel est le statut actuel", plus
    // robuste que de dupliquer cette logique ici.
    const { prod } = await getVerifiers()
    const txResult = await prod.verifyAndDecodeTransaction(signedTransactionInfo).catch(async () => {
      const { sandbox } = await getVerifiers()
      return await sandbox.verifyAndDecodeTransaction(signedTransactionInfo)
    })
    const tx = txResult.payload ?? txResult
    const originalTransactionId = String(tx.originalTransactionId)
    const environment: string | undefined = payload.data?.environment ?? tx.environment

    console.log(
      `[AppleNotifications] originalTransactionId=${originalTransactionId}, environment=${environment}`,
    )

    const { state } = await fetchAppleSubscription(originalTransactionId, environment)

    const db = adminClient()
    const owner = await saveSubscription(db, state, null)

    if (!owner) {
      // Transaction inconnue de notre base : l'utilisateur n'a probablement
      // jamais ouvert l'app pour déclencher verify-purchase une première fois.
      // On répond 200 quand même (rien à réessayer de notre côté) mais on log
      // pour investigation.
      console.warn(
        `[AppleNotifications] Aucun compte lié à originalTransactionId=${originalTransactionId} — abonnement non vérifié initialement`,
      )
    } else {
      console.log(`[AppleNotifications] Subscription updated for user ${owner}: status=${state.status}`)
    }

    await logNotification({
      notification_type: notificationType,
      subtype,
      original_transaction_id: originalTransactionId,
      environment,
      processed_ok: true,
    })

    return json({ status: "ok" })
  } catch (err) {
    // Erreur transitoire (DB, appel Apple...) : on répond 5xx pour qu'Apple
    // retente automatiquement la notification plus tard.
    console.error("[AppleNotifications] Processing error:", errMessage(err))
    await logNotification({
      notification_type: notificationType,
      subtype,
      processed_ok: false,
      error_message: errMessage(err),
    })
    return json({ error: "Processing error" }, 500)
  }
})