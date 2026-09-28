-- ============================================================
-- Table des abonnements (source de vérité), profiles.is_premium en dérive
-- ============================================================

create table if not exists public.subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null references auth.users(id) on delete cascade,
  platform                text not null check (platform in ('ios', 'android')),
  product_id              text not null,
  -- iOS : originalTransactionId | Android : purchaseToken
  original_transaction_id text not null,
  status                  text not null check (status in ('active','grace_period','billing_retry','expired','revoked')),
  -- Date jusqu'à laquelle l'accès est accordé (fin de période de grâce incluse)
  expires_at              timestamptz not null,
  auto_renew              boolean not null default false,
  environment             text,
  last_verified_at        timestamptz not null default now(),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  -- Un même achat ne peut appartenir qu'à un seul compte
  unique (platform, original_transaction_id)
);

create index if not exists subscriptions_user_idx    on public.subscriptions (user_id);
create index if not exists subscriptions_expires_idx on public.subscriptions (status, expires_at);

alter table public.subscriptions enable row level security;

-- Lecture de ses propres abonnements ; aucune écriture côté client (service role uniquement)
create policy "read own subscriptions" on public.subscriptions
  for select using (auth.uid() = user_id);

-- ============================================================
-- is_premium recalculé automatiquement à chaque changement
-- ============================================================

create or replace function public.refresh_premium(p_user uuid) returns void
language sql security definer set search_path = public as $$
  update public.profiles
  set is_premium = exists (
    select 1 from public.subscriptions s
    where s.user_id = p_user
      and s.status in ('active', 'grace_period')
      and s.expires_at > now()
  )
  where id = p_user;
$$;

create or replace function public.trg_subscriptions_refresh() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_premium(coalesce(new.user_id, old.user_id));
  return null;
end;
$$;

drop trigger if exists subscriptions_refresh on public.subscriptions;
create trigger subscriptions_refresh
  after insert or update or delete on public.subscriptions
  for each row execute function public.trg_subscriptions_refresh();

-- ============================================================
-- Filet de sécurité : coupe le premium à l'expiration même sans webhook
-- (ne touche QUE les utilisateurs qui ont au moins une ligne subscriptions,
--  donc les anciens premium sans ligne ne sont pas affectés)
-- ============================================================

create or replace function public.expire_premium() returns void
language sql security definer set search_path = public as $$
  update public.profiles p
  set is_premium = false
  where p.is_premium
    and exists (select 1 from public.subscriptions s where s.user_id = p.id)
    and not exists (
      select 1 from public.subscriptions s
      where s.user_id = p.id
        and s.status in ('active', 'grace_period')
        and s.expires_at > now()
    );
$$;

revoke all on function public.refresh_premium(uuid)       from public, anon, authenticated;
revoke all on function public.trg_subscriptions_refresh() from public, anon, authenticated;
revoke all on function public.expire_premium()            from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.schedule('expire-premium', '*/15 * * * *', $$select public.expire_premium()$$);

-- ============================================================
-- (Optionnel mais recommandé) Re-synchronisation périodique avec Apple/Google
-- Remplacer <PROJECT_REF> et <CRON_SECRET> (extension pg_net requise)
-- ============================================================
-- create extension if not exists pg_net;
-- select cron.schedule('sync-subscriptions', '*/30 * * * *', $$
--   select net.http_post(
--     url     := 'https://<PROJECT_REF>.supabase.co/functions/v1/sync-subscriptions',
--     headers := '{"x-cron-secret": "<CRON_SECRET>"}'::jsonb
--   );
-- $$);
