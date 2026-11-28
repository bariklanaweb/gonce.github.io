-- GONCE: pemisahan Mitra Food dan Mitra Toko
-- Jalankan satu kali di Supabase > SQL Editor > New query.
begin;

alter table public.stores
  add column if not exists store_type text not null default 'mitra';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'stores_store_type_check'
      and conrelid = 'public.stores'::regclass
  ) then
    alter table public.stores
      add constraint stores_store_type_check
      check (store_type in ('mitra','food'));
  end if;
end $$;

create index if not exists idx_stores_type_active
  on public.stores(store_type, is_active);

commit;
