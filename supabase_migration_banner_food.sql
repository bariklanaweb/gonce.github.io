-- GONCE: banner khusus untuk setiap Mitra Food
-- Jalankan satu kali di Supabase > SQL Editor > New query.
alter table public.stores
  add column if not exists food_banner_url text;
