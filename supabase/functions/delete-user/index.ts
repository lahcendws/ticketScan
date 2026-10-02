import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Authorization header missing')

    const token = authHeader.replace('Bearer ', '')
    const { data, error: authError } = await supabaseAdmin.auth.getUser(token)

    if (authError || !data?.user) throw new Error('Non autorisé')
    const user = data.user

    // --- NOUVEAU : Nettoyage du Storage ---
    // 1. Récupérer les chemins des images de l'utilisateur
    const { data: tickets } = await supabaseAdmin
      .from('tickets')
      .select('image_urls')
      .eq('user_id', user.id)

    // Extract image URLs safely, handling null/non-array values
    const imageUrls: string[] = []
    if (Array.isArray(tickets)) {
      for (const ticket of tickets) {
        if (ticket && typeof ticket === 'object' && 'image_urls' in ticket) {
          const urls = ticket.image_urls
          // Handle JSONB array stored as JS array
          if (Array.isArray(urls)) {
            imageUrls.push(...urls.filter((url): url is string => typeof url === 'string'))
          }
          // Handle JSONB stored as string (fallback)
          else if (typeof urls === 'string') {
            try {
              const parsed = JSON.parse(urls)
              if (Array.isArray(parsed)) {
                imageUrls.push(...parsed.filter((p): p is string => typeof p === 'string'))
              }
            } catch (e) {
              // Not valid JSON, ignore
            }
          }
        }
      }
    }

    // 2. Supprimer physiquement les fichiers
    if (imageUrls.length > 0) {
      await supabaseAdmin.storage.from('tickets').remove(imageUrls)
    }
    // ---------------------------------------

    // 3. Supprimer l'utilisateur (le CASCADE SQL supprimera les lignes en DB)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ message: 'Compte et données supprimés' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})