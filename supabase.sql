-- =========================================================
-- GONCE - SUPABASE DATABASE (BERSIH, IDEMPOTEN & TERURUT)
-- Jalankan SELURUH file ini di Supabase > SQL Editor > New query.
-- =========================================================

begin;

create extension if not exists pgcrypto;

-- 1. TABEL UTAMA
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  whatsapp text not null,
  address text not null,
  image_url text,
  food_banner_url text,
  description text,
  store_type text not null default 'mitra',
  latitude double precision,
  longitude double precision,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  price numeric(14,2) not null default 0,
  stock integer not null default 0,
  image_url text,
  category text,
  is_featured boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.banners (
  slot integer primary key,
  image_url text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id),
  customer_name text not null,
  customer_address text,
  total numeric(14,2) not null default 0,
  delivery_fee numeric(14,2) not null default 0,
  status text not null default 'baru',
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name text not null,
  quantity integer not null,
  unit_price numeric(14,2) not null,
  subtotal numeric(14,2) not null
);

-- 2. MIGRASI KOLOM AMAN (JIKA TABEL SUDAH ADA DARI VERSI SEBELUMNYA)
alter table public.stores
  add column if not exists name text,
  add column if not exists whatsapp text,
  add column if not exists address text,
  add column if not exists image_url text,
  add column if not exists food_banner_url text,
  add column if not exists description text,
  add column if not exists store_type text not null default 'mitra',
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

alter table public.products
  add column if not exists store_id uuid,
  add column if not exists name text,
  add column if not exists price numeric(14,2) not null default 0,
  add column if not exists stock integer not null default 0,
  add column if not exists image_url text,
  add column if not exists category text,
  add column if not exists is_featured boolean not null default false,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

alter table public.categories
  add column if not exists name text,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

alter table public.orders
  add column if not exists store_id uuid,
  add column if not exists customer_name text,
  add column if not exists customer_address text,
  add column if not exists total numeric(14,2) not null default 0,
  add column if not exists delivery_fee numeric(14,2) not null default 0,
  add column if not exists status text not null default 'baru',
  add column if not exists created_at timestamptz not null default now();

alter table public.order_items
  add column if not exists order_id uuid,
  add column if not exists product_id uuid,
  add column if not exists product_name text,
  add column if not exists quantity integer not null default 1,
  add column if not exists unit_price numeric(14,2) not null default 0,
  add column if not exists subtotal numeric(14,2) not null default 0;

-- 3. CONSTRAINT AMAN (TANPA GAGAL JIKA SUDAH ADA)
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

  if not exists (
    select 1 from pg_constraint
    where conname = 'categories_name_key'
      and conrelid = 'public.categories'::regclass
  ) then
    alter table public.categories
      add constraint categories_name_key unique (name);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'banners_slot_check'
      and conrelid = 'public.banners'::regclass
  ) then
    alter table public.banners
      add constraint banners_slot_check
      check (slot between 1 and 3);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'products_price_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_price_check check (price >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'products_stock_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_stock_check check (stock >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_total_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_total_check check (total >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'orders_delivery_fee_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_delivery_fee_check check (delivery_fee >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'order_items_quantity_check'
      and conrelid = 'public.order_items'::regclass
  ) then
    alter table public.order_items
      add constraint order_items_quantity_check check (quantity > 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'order_items_unit_price_check'
      and conrelid = 'public.order_items'::regclass
  ) then
    alter table public.order_items
      add constraint order_items_unit_price_check check (unit_price >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'order_items_subtotal_check'
      and conrelid = 'public.order_items'::regclass
  ) then
    alter table public.order_items
      add constraint order_items_subtotal_check check (subtotal >= 0);
  end if;
end $$;

-- 4. INDEX
create index if not exists idx_categories_active_name on public.categories(is_active, name);
create index if not exists idx_products_store_id on public.products(store_id);
create index if not exists idx_products_active_created on public.products(is_active, created_at desc);
create index if not exists idx_stores_active_created on public.stores(is_active, created_at desc);
create index if not exists idx_stores_type_active on public.stores(store_type, is_active);
create index if not exists idx_orders_created on public.orders(created_at desc);
create index if not exists idx_order_items_order_id on public.order_items(order_id);

-- 5. RLS & PERMISSION (TERURUT: DROP POLICY -> ALTER ENABLE RLS -> CREATE POLICY -> GRANT)
do $$
declare
  v_table text;
  v_policy record;
begin
  foreach v_table in array array['stores','products','categories','banners','app_settings','orders','order_items'] loop
    for v_policy in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = v_table
    loop
      execute format('drop policy if exists %I on public.%I', v_policy.policyname, v_table);
    end loop;
  end loop;
end $$;

alter table public.stores enable row level security;
alter table public.products enable row level security;
alter table public.categories enable row level security;
alter table public.banners enable row level security;
alter table public.app_settings enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "Gonce public app settings access" on public.app_settings
  for all to anon, authenticated using (true) with check (true);
create policy "Gonce public stores access" on public.stores
  for all to anon, authenticated using (true) with check (true);
create policy "Gonce public products access" on public.products
  for all to anon, authenticated using (true) with check (true);
create policy "Gonce public categories access" on public.categories
  for all to anon, authenticated using (true) with check (true);
create policy "Gonce public banners access" on public.banners
  for all to anon, authenticated using (true) with check (true);
create policy "Gonce public orders access" on public.orders
  for select to anon, authenticated using (true);
create policy "Gonce public order items access" on public.order_items
  for select to anon, authenticated using (true);

revoke all on public.stores, public.products, public.categories, public.banners, public.orders, public.order_items from anon;
revoke all on public.orders, public.order_items from authenticated;
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.stores, public.products, public.categories, public.banners, public.app_settings to anon, authenticated;
grant select on public.orders, public.order_items to anon, authenticated;

-- 6. RPC CHECKOUT ATOMIK (TANPA ONGKIR)
create or replace function public.checkout_order(
  p_store_id uuid,
  p_customer_name text,
  p_customer_address text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_order_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty integer;
  v_name text;
  v_price numeric(14,2);
  v_stock integer;
  v_total numeric(14,2) := 0;
  v_subtotal numeric(14,2);
begin
  if p_store_id is null then
    raise exception 'Toko wajib dipilih';
  end if;

  if nullif(trim(coalesce(p_customer_name, '')), '') is null then
    raise exception 'Nama pemesan wajib diisi';
  end if;

  if p_items is null
     or jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang pesanan kosong';
  end if;

  if not exists (
    select 1 from public.stores
    where id = p_store_id and is_active = true
  ) then
    raise exception 'Toko tidak ditemukan atau tidak aktif';
  end if;

  insert into public.orders
    (store_id, customer_name, customer_address, total, delivery_fee, status)
  values
    (p_store_id, trim(p_customer_name), coalesce(p_customer_address, ''), 0, 0, 'baru')
  returning id into v_order_id;

  for v_item in
    select value from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item->>'product_id', '') = ''
       or coalesce(v_item->>'quantity', '') !~ '^[0-9]+$' then
      raise exception 'Data produk atau jumlah pesanan tidak valid';
    end if;

    v_product_id := (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;

    if v_qty < 1 then
      raise exception 'Jumlah produk minimal 1';
    end if;

    select p.name, p.price, p.stock
      into v_name, v_price, v_stock
      from public.products p
     where p.id = v_product_id
       and p.store_id = p_store_id
       and p.is_active = true
     for update;

    if not found then
      raise exception 'Produk tidak ditemukan atau tidak aktif';
    end if;

    if v_stock < v_qty then
      raise exception 'Stok produk % tidak mencukupi', v_name;
    end if;

    update public.products
       set stock = stock - v_qty
     where id = v_product_id;

    v_subtotal := v_price * v_qty;
    v_total := v_total + v_subtotal;

    insert into public.order_items
      (order_id, product_id, product_name, quantity, unit_price, subtotal)
    values
      (v_order_id, v_product_id, v_name, v_qty, v_price, v_subtotal);
  end loop;

  update public.orders
     set total = v_total
   where id = v_order_id;

  return jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'total', v_total
  );
end;
$function$;

revoke all on function public.checkout_order(uuid, text, text, jsonb) from public;
grant execute on function public.checkout_order(uuid, text, text, jsonb) to anon, authenticated;

-- 7. RPC CHECKOUT ATOMIK + ONGKIR
create or replace function public.checkout_order_with_delivery(
  p_store_id uuid,
  p_customer_name text,
  p_customer_address text,
  p_items jsonb,
  p_delivery_fee numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_order_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty integer;
  v_name text;
  v_price numeric(14,2);
  v_stock integer;
  v_total numeric(14,2) := 0;
  v_subtotal numeric(14,2);
  v_delivery_fee numeric(14,2) := greatest(0, coalesce(p_delivery_fee, 0));
begin
  if p_store_id is null then
    raise exception 'Toko wajib dipilih';
  end if;

  if nullif(trim(coalesce(p_customer_name, '')), '') is null then
    raise exception 'Nama pemesan wajib diisi';
  end if;

  if p_items is null
     or jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang pesanan kosong';
  end if;

  if not exists (
    select 1 from public.stores
    where id = p_store_id and is_active = true
  ) then
    raise exception 'Toko tidak ditemukan atau tidak aktif';
  end if;

  insert into public.orders
    (store_id, customer_name, customer_address, total, delivery_fee, status)
  values
    (p_store_id, trim(p_customer_name), coalesce(p_customer_address, ''), 0, v_delivery_fee, 'baru')
  returning id into v_order_id;

  for v_item in
    select value from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item->>'product_id', '') = ''
       or coalesce(v_item->>'quantity', '') !~ '^[0-9]+$' then
      raise exception 'Data produk atau jumlah pesanan tidak valid';
    end if;

    v_product_id := (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;

    if v_qty < 1 then
      raise exception 'Jumlah produk minimal 1';
    end if;

    select p.name, p.price, p.stock
      into v_name, v_price, v_stock
      from public.products p
     where p.id = v_product_id
       and p.store_id = p_store_id
       and p.is_active = true
     for update;

    if not found then
      raise exception 'Produk tidak ditemukan atau tidak aktif';
    end if;

    if v_stock < v_qty then
      raise exception 'Stok produk % tidak mencukupi', v_name;
    end if;

    update public.products
       set stock = stock - v_qty
     where id = v_product_id;

    v_subtotal := v_price * v_qty;
    v_total := v_total + v_subtotal;

    insert into public.order_items
      (order_id, product_id, product_name, quantity, unit_price, subtotal)
    values
      (v_order_id, v_product_id, v_name, v_qty, v_price, v_subtotal);
  end loop;

  update public.orders
     set total = v_total + v_delivery_fee
   where id = v_order_id;

  return jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'subtotal', v_total,
    'delivery_fee', v_delivery_fee,
    'total', v_total + v_delivery_fee
  );
end;
$function$;

revoke all on function public.checkout_order_with_delivery(uuid, text, text, jsonb, numeric) from public;
grant execute on function public.checkout_order_with_delivery(uuid, text, text, jsonb, numeric) to anon, authenticated;

commit;
