-- Fix foreign key constraint on ticket_hashes to allow CASCADE delete
-- This resolves the issue where users cannot be deleted due to RESTRICT constraint on ticket_hashes

ALTER TABLE "public"."ticket_hashes"
  DROP CONSTRAINT IF EXISTS "ticket_hashes_user_id_fkey",
  ADD CONSTRAINT "ticket_hashes_user_id_fkey"
    FOREIGN KEY (user_id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;