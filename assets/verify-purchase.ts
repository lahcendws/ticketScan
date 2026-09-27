import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { receipt, productId, platform } = await req.json()
    
    // Basic validation
    if (!receipt || typeof receipt !== 'string' || receipt.trim() === '') {
      throw new Error('Receipt is missing or empty')
    }
    if (!productId || typeof productId !== 'string') {
      throw new Error('ProductId is missing or invalid')
    }
    if (!platform || !(platform === 'android' || platform === 'ios')) {
      throw new Error('Platform must be android or ios')
    }

    console.log(`Verifying purchase: platform=${platform}, productId=${productId}, receipt length=${receipt.length}`)

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
      // -------- GOOGLE PLAY VERIFICATION --------
      const serviceAccount = JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")!)
      const { GoogleAuth } = await import('https://esm.sh/google-auth-library@9.0.0')
      const auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      })
      const client = await auth.getClient()
      const accessToken = (await client.getAccessToken()).token

      const packageName = "com.devevolu.ticketscan"
      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${receipt}`
    
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
      // -------- APPLE APP STORE VERIFICATION --------
      const sharedSecret = Deno.env.get('APPLE_SHARED_SECRET')
      if (!sharedSecret) throw new Error('APPLE_SHARED_SECRET non configuré')

      const verifyUrl = 'https://buy.itunes.apple.com/verifyReceipt' // production
      const payload = {
        'receipt-data': receipt,
        'password': sharedSecret,
        'exclude-old-transactions': true
      }

      let verifyRes = await fetch(verifyUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })
      let data = await verifyRes.json()

      // Handle sandbox redirect
      if (data.status === 21007 || data.status === 21008) {
        console.log(`Apple production returned ${data.status}, trying sandbox`)
        const sandboxUrl = 'https://sandbox.itunes.apple.com/verifyReceipt'
        verifyRes = await fetch(sandboxUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })
        data = await verifyRes.json()
        if (verifyRes.status !== 200 || data.status !== 0) {
          console.error(`Apple sandbox verification failed: status=${verifyRes.status}, body=${JSON.stringify(data)}`)
          throw new Error(`Erreur Apple (sandbox): ${data.status}`)
        }
      }

      if (data.status !== 0) {
        console.error(`Apple verification failed: status=${data.status}`)
        throw new Error(`Erreur Apple: ${data.status}`)
      }

      // Find the latest receipt info for this product_id
      const latestInfo = data.latest_receipt_info?.find((info: any) => info.product_id === productId)
      if (!latestInfo) {
        // Maybe receipt is for a different product or expired
        throw new Error('Receipt info not found for product')
      }

      const expiresDateMs = parseInt(latestInfo.expires_date_ms || "0")
      const isExpired = expiresDateMs <= Date.now()

      if (!isExpired) {
        // Update profile
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
    } else {
      throw new Error(`Plateforme non supportée: ${platform}`)
    }

  } catch (error) {
    console.error("Erreur critique validation:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
