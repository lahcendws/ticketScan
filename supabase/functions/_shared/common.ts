import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2"

export const APPLE_BUNDLE_ID = "com.devevolu.ticketscan"
export const ANDROID_PACKAGE = "com.devevolu.ticketscan"
export const ALLOWED_PRODUCTS = ["premium_yearly", "premium_monthly"]

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message)
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

export function errMessage(e: unknown): string {
  if (e instanceof Error) return e.message
  if (e && typeof e === "object" && "message" in e) return String((e as any).message)
  return String(e)
}

export function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  )
}

// ------------------------------------------------------------
// Modèle commun Apple / Google
// ------------------------------------------------------------

export type SubStatus =
  | "active"
  | "grace_period"
  | "billing_retry"
  | "expired"
  | "revoked"

export interface SubscriptionState {
  platform: "ios" | "android"
  productId: string
  originalTransactionId: string // iOS: originalTransactionId, Android: purchaseToken
  status: SubStatus
  expiresAt: Date // accès accordé jusqu'à (grâce incluse)
  autoRenew: boolean
  environment: string
  replaces?: string // Android : ancien purchaseToken remplacé (upgrade / réabonnement)
}

export function isEntitled(s: SubscriptionState): boolean {
  return (
    (s.status === "active" || s.status === "grace_period") &&
    s.expiresAt.getTime() > Date.now()
  )
}

/**
 * Enregistre l'état d'un abonnement.
 * - userId fourni (appel client authentifié) : rattache l'abonnement à ce compte.
 * - userId null (webhook / cron) : met à jour uniquement un abonnement déjà connu.
 * Retourne l'id utilisateur propriétaire, ou null si l'abonnement est inconnu.
 * profiles.is_premium est recalculé par le trigger SQL.
 */
export async function saveSubscription(
  db: SupabaseClient,
  s: SubscriptionState,
  userId: string | null,
): Promise<string | null> {
  const { data: existing, error } = await db
    .from("subscriptions")
    .select("user_id")
    .eq("platform", s.platform)
    .eq("original_transaction_id", s.originalTransactionId)
    .maybeSingle()
  if (error) throw error

  // If there's an existing subscription for a different user, we transfer it
  // to the current user when we have a verified purchase (userId is provided)
  // since we've already validated the purchase receipt with Apple/Google
  let owner: string | null = null
  if (existing && userId && existing.user_id !== userId) {
    console.log(
      `[saveSubscription] Transferring subscription from user ${existing.user_id} to user ${userId}`
    )
    owner = userId // Transfer to current user
  } else {
    // Either no existing subscription, or it's already for the same user
    owner = existing?.user_id ?? userId
  }

  // Android : un nouveau token qui en remplace un autre hérite du même utilisateur
  if (!owner && s.replaces) {
    const { data: old } = await db
      .from("subscriptions")
      .select("user_id")
      .eq("platform", s.platform)
      .eq("original_transaction_id", s.replaces)
      .maybeSingle()
    owner = old?.user_id ?? null
  }

  if (!owner) return null

  const now = new Date().toISOString()

  const { error: upsertError } = await db.from("subscriptions").upsert(
    {
      user_id: owner,
      platform: s.platform,
      product_id: s.productId,
      original_transaction_id: s.originalTransactionId,
      status: s.status,
      expires_at: s.expiresAt.toISOString(),
      auto_renew: s.autoRenew,
      environment: s.environment,
      last_verified_at: now,
      updated_at: now,
    },
    { onConflict: "platform,original_transaction_id" },
  )
  if (upsertError) throw upsertError

  if (s.replaces) {
    await db
      .from("subscriptions")
      .update({ status: "expired", expires_at: now, updated_at: now })
      .eq("platform", s.platform)
      .eq("original_transaction_id", s.replaces)
  }

  return owner
}
