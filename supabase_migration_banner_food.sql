-- GONCE: banner khusus untuk setiap Mitra Food (rasio tampilan 2:1)
-- Jalankan satu kali di Supabase > SQL Editor > New query.
-- Aman untuk data lama: hanya menambahkan kolom baru.
alter table public.stores
  add column if not exists food_banner_url text;
