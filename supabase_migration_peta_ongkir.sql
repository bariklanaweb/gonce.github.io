-- GONCE: MIGRASI PETA TOKO DAN ONGKIR FOOD
-- Jalankan file ini di Supabase SQL Editor > New query.
-- Aman untuk database yang sudah berisi toko/produk; tidak menghapus data.

alter table public.stores
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.orders
  add column if not exists delivery_fee numeric(14,2) not null default 0;

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
  v_delivery_fee numeric(14,2) := greatest(0, coalesce(p_delivery_fee,0));
begin
  if p_store_id is null then raise exception 'Toko wajib dipilih'; end if;
  if nullif(trim(coalesce(p_customer_name, '')), '') is null then raise exception 'Nama pemesan wajib diisi'; end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items)=0 then raise exception 'Keranjang pesanan kosong'; end if;
  if not exists (select 1 from public.stores where id=p_store_id and is_active=true) then raise exception 'Toko tidak ditemukan atau tidak aktif'; end if;

  insert into public.orders(store_id,customer_name,customer_address,total,delivery_fee,status)
  values(p_store_id,trim(p_customer_name),coalesce(p_customer_address,''),0,v_delivery_fee,'baru')
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if coalesce(v_item->>'product_id','')='' or coalesce(v_item->>'quantity','') !~ '^[0-9]+$' then raise exception 'Data produk atau jumlah pesanan tidak valid'; end if;
    v_product_id := (v_item->>'product_id')::uuid;
    v_qty := (v_item->>'quantity')::integer;
    if v_qty<1 then raise exception 'Jumlah produk minimal 1'; end if;
    select p.name,p.price,p.stock into v_name,v_price,v_stock from public.products p
      where p.id=v_product_id and p.store_id=p_store_id and p.is_active=true for update;
    if not found then raise exception 'Produk tidak ditemukan atau tidak aktif'; end if;
    if v_stock<v_qty then raise exception 'Stok produk % tidak mencukupi',v_name; end if;
    update public.products set stock=stock-v_qty where id=v_product_id;
    v_subtotal:=v_price*v_qty;
    v_total:=v_total+v_subtotal;
    insert into public.order_items(order_id,product_id,product_name,quantity,unit_price,subtotal)
      values(v_order_id,v_product_id,v_name,v_qty,v_price,v_subtotal);
  end loop;

  update public.orders set total=v_total+v_delivery_fee where id=v_order_id;
  return jsonb_build_object('success',true,'order_id',v_order_id,'subtotal',v_total,'delivery_fee',v_delivery_fee,'total',v_total+v_delivery_fee);
end;
$function$;

revoke all on function public.checkout_order_with_delivery(uuid,text,text,jsonb,numeric) from public;
grant execute on function public.checkout_order_with_delivery(uuid,text,text,jsonb,numeric) to anon, authenticated;
