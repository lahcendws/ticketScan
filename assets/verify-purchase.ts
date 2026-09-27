/// <reference types="@deno" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const APPLE_API_URL = 'https://api.storekit.apple.com/inApps/v1/signatures/'

// Helper function to convert PEM string to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const lines = pem.split('\n')
  // Remove header and footer lines
  const encoded = lines.slice(1, -1).join('')
  // Decode base64
  const binary = atob(encoded)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i)
  }
  return buffer
}

// Base64URL encode without padding
function base64urlEncode(source: ArrayBuffer): string {
  // Convert ArrayBuffer to Uint8Array then to base64
  const binary = String.fromCharCode(...new Uint8Array(source))
  let base64 = btoa(binary)
  // Replace +/ with -_ and remove padding =
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { signedTransaction, productId, platform } = await req.json()

    // Basic validation
    if (!signedTransaction || typeof signedTransaction !== 'string') {
      throw new Error('signedTransaction is missing or invalid')
    }
    if (!productId || typeof productId !== 'string') {
      throw new Error('productId is missing or invalid')
    }
    if (!platform || !(platform === 'android' || platform === 'ios')) {
      throw new Error('platform must be android or ios')
    }

    console.log(`Verifying purchase: platform=${platform}, productId=${productId}, signedTransaction length=${signedTransaction.length}`)

    // 1. Initialiser Supabase Admin (Bypass RLS pour mettre à jour le profil)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 2. Récupérer l'ID de l'utilisateur via son jeton d'authentification
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    if (userError || !user) throw new Error('Utilisateur non identifié')

    if (platform === 'android') {
      // -------- GOOGLE PLAY VERIFICATION (existing flow) --------
      const serviceAccount = JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")!)
      // @ts-ignore
      const { GoogleAuth } = await import('https://esm.sh/google-auth-library@9.0.0')
      const auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      })
      const client = await auth.getClient()
      const accessToken = (await client.getAccessToken()).token

      const packageName = "com.devevolu.ticketscan"
      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${signedTransaction}`

      const verifyRes = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } })
      let data = await verifyRes.json()

      if (verifyRes.status !== 200) {
        console.error(`Google Play verification failed: status=${verifyRes.status}, body=${JSON.stringify(data)}`)
        throw new Error(`Erreur Google: ${data.error?.message || verifyRes.statusText}`)
      }

      // IMPORTANT : Accuser réception (Acknowledge)
      if (data.acknowledgementState === 0) {
        await fetch(`${url}:acknowledge`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        })
        console.log("Achat acquitté auprès de Google.");
      }

      // Vérifier si l'abonnement est toujours valide
      const expiryTime = parseInt(data.expiryTimeMillis || "0")
      if (expiryTime > Date.now()) {
        // MISE À JOUR SÉCURISÉE DU PROFIL
        const { error: updateError } = await supabaseAdmin
          .from('profiles')
          .update({ is_premium: true })
          .eq('id', user.id)

        if (updateError) throw updateError

        return new Response(JSON.stringify({ status: 'success' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        })
      } else {
        throw new Error('L\'abonnement a expiré')
      }
    } else if (platform === 'ios') {
      // -------- APPLE APP STORE VERIFICATION (StoreKit 2) --------
      // Validate JWT signature format (three parts separated by dots)
      const parts = signedTransaction.split('.')
      if (parts.length !== 3) {
        throw new Error('Invalid signedTransaction format (expected JWS with three parts)')
      }

      // Prepare JWT for Apple API calls
      const applePrivateKeyEnv = Deno.env.get('APPLE_PRIVATE_KEY')
      const appleKeyId = Deno.env.get('APPLE_KEY_ID')
      const appleIssuerId = Deno.env.get('APPLE_ISSUER_ID')
      console.log(`Apple env check: privateKey present=${!!applePrivateKeyEnv}, keyId present=${!!appleKeyId}, issuerId present=${!!appleIssuerId}`)
      if (!applePrivateKeyEnv || !appleKeyId || !appleIssuerId) {
        throw new Error('Apple credentials not configured in Supabase edge function')
      }

      // Convert PEM to CryptoKey
      let applePrivateKey = applePrivateKeyEnv
      // Handle literal \n in the string (if supplied as JSON string)
      if (applePrivateKey.includes('\\n') && !applePrivateKey.includes('\n')) {
        // Replace \n (two chars) with actual newline
        applePrivateKey = applePrivateKey.replace(/\\n/g, '\n')
      }
      // Import the private key
      const cryptoKey = await crypto.subtle.importKey(
        "pkcs8",
        pemToArrayBuffer(applePrivateKey),
        { name: "ECDSA", namedCurve: "P-256" }, // ES256 uses P-256
        true, // extractable
        ["sign"] // we only need to sign
      )

      // Create header and payload for JWT
      const iat = Math.floor(Date.now() / 1000)
      const exp = iat + 20 * 60 // 20 minutes
      const headerObj = { alg: 'ES256', kid: appleKeyId, typ: 'JWT' }
      const payloadObj = { iss: appleIssuerId, iat, exp, aud: 'appstoreconnect-v1' }
      console.log(`JWT header:`, headerObj)
      console.log(`JWT payload:`, payloadObj)

      // Encode header and payload as base64url
      const headerStr = JSON.stringify(headerObj)
      const payloadStr = JSON.stringify(payloadObj)
      const headerBytes = new TextEncoder().encode(headerStr)
      const payloadBytes = new TextEncoder().encode(payloadStr)
      const headerB64 = base64urlEncode(headerBytes)
      const payloadB64 = base64urlEncode(payloadBytes)

      // Concatenate header and payload with a dot
      const unsignedToken = `${headerB64}.${payloadB64}`

      // Sign the unsignedToken
      let signatureBytes: ArrayBuffer
      try {
        signatureBytes = await crypto.subtle.sign(
          { name: "ECDSA", hash: { name: "SHA-256" } }, // ECDSA with SHA-256 for ES256
          cryptoKey,
          new TextEncoder().encode(unsignedToken)
        )
      } catch (signError) {
        console.error(`JWT signing failed: ${signError}`)
        throw new Error(`Failed to sign JWT for Apple API: ${signError}`)
      }
      const signatureB64 = base64urlEncode(signatureBytes)

      // Assemble the JWT
      const jwt = `${unsignedToken}.${signatureB64}`
      console.log(`JWT created successfully, length: ${jwt.length}`)

      // Call Apple's App Store Server API to verify the signed transaction
      const verifyUrl = `${APPLE_API_URL}${encodeURIComponent(signedTransaction)}`
      const verifyRes = await fetch(verifyUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${jwt}`,
          'Content-Type': 'application/json'
        }
      })
      const appleData = await verifyRes.json()

      if (!verifyRes.ok) {
        console.error(`Apple App Store Server API failed: status=${verifyRes.status}, body=${JSON.stringify(appleData)}`)
        throw new Error(`Erreur Apple: ${appleData?.['error']?.[0]?.['message'] || verifyRes.statusText}`)
      }

      // Extract the latest transaction info from the response
      // The response format: { data: [ { signedTransactionInfo: { ... } } ], ... }
      const dataArray = appleData.data as Array<any> || []
      if (dataArray.length === 0) {
        throw new Error('No transaction data returned from Apple')
      }

      // Get the latest transaction (first in array)
      const latestTransaction = dataArray[0]
      const signedTransactionInfo = latestTransaction.signedTransactionInfo
      if (!signedTransactionInfo) {
        throw new Error('Missing signedTransactionInfo in Apple response')
      }

      // Parse the signedTransactionInfo (it's a base64url encoded JWS payload)
      // According to Apple docs, the signedTransactionInfo is a JSON string containing the payload.
      // We'll parse it directly.
      let transactionInfo: any
      try {
        transactionInfo = JSON.parse(signedTransactionInfo)
      } catch (e) {
        // Maybe it's still a JWS? We'll try to decode the payload part.
        // Split the signedTransactionInfo (which is a JWS) and decode the payload.
        const infoParts = signedTransactionInfo.split('.')
        if (infoParts.length !== 3) {
          throw new Error('Invalid signedTransactionInfo format')
        }
        const payloadPart = infoParts[1]
        // Add padding if needed
        const padded = payloadPart.replace(/-/g, '+').replace(/_/g, '/')
        const decoded = atob(padded)
        transactionInfo = JSON.parse(decoded)
      }

      // Validate productId
      if (transactionInfo.productId !== productId) {
        throw new Error(`Product ID mismatch: expected ${productId}, got ${transactionInfo.productId}`)
      }

      // Check expiration date (in milliseconds since epoch)
      const expiresDate = parseInt(transactionInfo.expiresDate || "0")
      if (isNaN(expiresDate) || expiresDate <= Date.now()) {
        throw new Error('L\'abonnement a expiré')
      }

      // MISE À JOUR SÉCURISÉE DU PROFIL
      const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({ is_premium: true })
        .eq('id', user.id)

      if (updateError) throw updateError

      return new Response(JSON.stringify({ status: 'success' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    } else {
      throw new Error(`Plateforme non supportée: ${platform}`)
    }

  } catch (error: unknown) {
    if (error instanceof Error) {
      console.error("Erreur critique validation:", error.message)
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    } else {
      console.error("Erreur critique validation:", String(error))
      return new Response(JSON.stringify({ error: String(error) }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }
  }
})