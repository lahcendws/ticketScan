import {
  APPLE_BUNDLE_ID,
  HttpError,
  SubscriptionState,
  SubStatus,
} from "./common.ts"

const HOSTS: Record<string, string> = {
  Production: "https://api.storekit.apple.com",
  Sandbox: "https://api.storekit-sandbox.apple.com",
}

// ------------------------------------------------------------
// Helpers base64 / JWS
// ------------------------------------------------------------

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const clean = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "")
  const binary = atob(clean)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) view[i] = binary.charCodeAt(i)
  return buffer
}

function b64urlEncode(source: ArrayBuffer | Uint8Array): string {
  const bytes = source instanceof Uint8Array ? source : new Uint8Array(source)
  let binary = ""
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

function b64urlDecode(value: string): string {
  let b64 = value.replace(/-/g, "+").replace(/_/g, "/")
  while (b64.length % 4 !== 0) b64 += "="
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return new TextDecoder().decode(bytes)
}

/**
 * Décode le payload d'un JWS SANS vérifier la signature.
 * À n'utiliser que comme indice (environnement, transactionId) : la donnée
 * qui fait foi est toujours re-récupérée auprès de l'API Apple authentifiée.
 */
export function decodeJws(jws: string): any {
  const parts = jws.split(".")
  if (parts.length !== 3) throw new HttpError(400, "JWS Apple invalide")
  try {
    return JSON.parse(b64urlDecode(parts[1]))
  } catch (e) {
    throw new HttpError(400, `Impossible de décoder le JWS Apple: ${e}`)
  }
}

// ------------------------------------------------------------
// JWT Apple (mis en cache ~10 min)
// ------------------------------------------------------------

let jwtCache: { token: string; exp: number } | null = null

async function appleJwt(): Promise<string> {
  const nowSec = Math.floor(Date.now() / 1000)
  if (jwtCache && jwtCache.exp - 60 > nowSec) {
    console.log('[AppleService] Using cached JWT')
    return jwtCache.token
  }

  console.log('[AppleService] Generating new JWT')
  const privateKeyEnv = Deno.env.get("APPLE_PRIVATE_KEY")
  const keyId = Deno.env.get("APPLE_KEY_ID")
  const issuerId = Deno.env.get("APPLE_ISSUER_ID")
  
  console.log(`[AppleService] Checking Apple credentials: privateKey=${!!privateKeyEnv}, keyId=${!!keyId}, issuerId=${!!issuerId}`)
  
  if (!privateKeyEnv || !keyId || !issuerId) {
    const missing = []
    if (!privateKeyEnv) missing.append('APPLE_PRIVATE_KEY')
    if (!keyId) missing.append('APPLE_KEY_ID')
    if (!issuerId) missing.append('APPLE_ISSUER_ID')
    throw new HttpError(500, `APPLE_PRIVATE_KEY, APPLE_KEY_ID ou APPLE_ISSUER_ID manquant: ${missing.join(', ')}`)
  }

  let pem = privateKeyEnv
  if (pem.includes("\\n") && !pem.includes("\n")) {
    console.log('[AppleService] Converting escaped newlines to actual newlines')
    pem = pem.replace(/\\n/g, "\n")
  }

  try {
    console.log('[AppleService] Importing private key')
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pemToArrayBuffer(pem),
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    )

    const exp = nowSec + 900
    const enc = new TextEncoder()
    const header = b64urlEncode(enc.encode(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" })))
    const payload = b64urlEncode(enc.encode(JSON.stringify({
      iss: issuerId,
      iat: nowSec,
      exp,
      aud: "appstoreconnect-v1",
      bid: APPLE_BUNDLE_ID,
    })))
    const unsigned = `${header}.${payload}`
    console.log(`[AppleService] JWT unsigned token created (length: ${unsigned.length})`)
    
    const sig = await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      enc.encode(unsigned),
    )

    const token = `${unsigned}.${b64urlEncode(sig)}`
    jwtCache = { token, exp }
    console.log('[AppleService] JWT generated and cached successfully')
    return token
  } catch (error) {
    console.error('[AppleService] Failed to generate JWT:', error)
    throw new HttpError(500, `Failed to generate Apple JWT: ${error.message}`)
  }
}

// ------------------------------------------------------------
// Appel API avec fallback d'environnement + retry
// ------------------------------------------------------------

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

async function appleGet(path: string, envHint?: string): Promise<any> {
  console.log(`[AppleService] Making API call to: ${path} (envHint: ${envHint ?? 'none'})`)
  const jwt = await appleJwt()
  const order = envHint === "Sandbox" ? ["Sandbox", "Production"] : ["Production", "Sandbox"]

  for (const env of order) {
    console.log(`[AppleService] Trying environment: ${env}`)
    for (let attempt = 0; attempt < 3; attempt++) {
      console.log(`[AppleService] Attempt ${attempt + 1}/3 for ${env}`)
      const res = await fetch(HOSTS[env] + path, {
        headers: { Authorization: `Bearer ${jwt}`, Accept: "application/json" },
      })

      if (res.ok) {
        console.log(`[AppleService] API call successful: ${res.status}`)
        return await res.json()
      }

      // Transaction inconnue dans cet environnement → on tente l'autre
      if (res.status === 404) {
        console.log(`[AppleService] Transaction not found in ${env}, trying other environment`)
        break
      }

      const text = (await res.text()).slice(0, 300)

      // Erreurs temporaires → retry avec backoff, puis 503 (Apple/Supabase réessaieront)
      if (res.status === 429 || res.status >= 500) {
        console.log(`[AppleService] Temporary error ${res.status}, retrying...`)
        if (attempt === 2) {
          console.error(`[AppleService] Max retries exceeded for ${env}`)
          throw new HttpError(503, `Apple HTTP ${res.status}: ${text}`)
        }
        await sleep(500 * 2 ** attempt)
        continue
      }

      // 401 = notre JWT/clé est mauvaise : erreur de configuration côté serveur
      // Cependant, dans le contexte d'essayer les deux environnements, on continue à essayer
      // car le 401 pourrait être dû à un mauvais environnement plutôt qu'à des mauvais credentials
      console.error(`[AppleService] JWT authentication failed (401) for ${env}: ${text}`)
      if (attempt === 2) {
        console.error(`[AppleService] Max retries exceeded for ${env}`)
        throw new HttpError(res.status === 401 ? 500 : 502, `Apple HTTP ${res.status}: ${text}`)
      }
      await sleep(500 * 2 ** attempt)
      continue
    }
  }

  console.error('[AppleService] Transaction not found in any environment')
  throw new HttpError(404, "Transaction Apple introuvable (production et sandbox)")
}

// ------------------------------------------------------------
// État de l'abonnement
// ------------------------------------------------------------

const STATUS_MAP: Record<number, SubStatus> = {
  1: "active",
  2: "expired",
  3: "billing_retry",
  4: "grace_period",
  5: "revoked",
}

/**
 * Récupère l'état courant de l'abonnement via "Get All Subscription Statuses".
 * Accepte n'importe quel transactionId de l'abonnement (dont originalTransactionId).
 * C'est cet appel qui permet de détecter renouvellements, annulations,
 * remboursements, relance de paiement et période de grâce.
 */
export async function fetchAppleSubscription(
  transactionId: string,
  envHint?: string,
): Promise<{ state: SubscriptionState; appAccountToken?: string }> {
  console.log(`[AppleService] Fetching subscription status for transactionId: ${transactionId}`)
  const res = await appleGet(
    `/inApps/v1/subscriptions/${encodeURIComponent(transactionId)}`,
    envHint,
  )

  if (res.bundleId && res.bundleId !== APPLE_BUNDLE_ID) {
    throw new HttpError(400, `Bundle ID Apple invalide: ${res.bundleId}`)
  }

  const entry = (res.data ?? []).flatMap((g: any) => g.lastTransactions ?? [])[0]
  if (!entry?.signedTransactionInfo) {
    throw new HttpError(404, "Aucun abonnement Apple trouvé pour cette transaction")
  }

  const tx = decodeJws(entry.signedTransactionInfo)
  const renewal = entry.signedRenewalInfo ? decodeJws(entry.signedRenewalInfo) : null

  if (tx.bundleId !== APPLE_BUNDLE_ID) {
    throw new HttpError(400, `Bundle ID Apple invalide: ${tx.bundleId}`)
  }

  let status: SubStatus = STATUS_MAP[entry.status] ?? "expired"
  if (tx.revocationDate) status = "revoked"

  let expiresAtMs = Number(tx.expiresDate || 0)
  // Période de grâce : l'accès continue jusqu'à gracePeriodExpiresDate
  if (status === "grace_period" && renewal?.gracePeriodExpiresDate) {
    expiresAtMs = Number(renewal.gracePeriodExpiresDate)
  }

  const result = {
    appAccountToken: tx.appAccountToken,
    state: {
      platform: "ios",
      productId: tx.productId,
      originalTransactionId: String(tx.originalTransactionId),
      status,
      expiresAt: new Date(expiresAtMs),
      autoRenew: renewal?.autoRenewStatus === 1,
      environment: tx.environment ?? res.environment ?? "Production",
    },
  }
  
  console.log(`[AppleService] Subscription status: ${JSON.stringify(result.state)}`)
  return result
}
