-- StockFlow v1.4.0
-- Full private seller pickup/dispatch address, separate from public listing data
-- and separate from the coordinate-only analytics table.

create table if not exists public.staging_listing_addresses (
  listing_id uuid primary key references public.staging_listings(id) on delete cascade,
  seller_id uuid not null references public.staging_users(id) on delete cascade,
  address_line1 text not null,
  street text,
  locality text,
  district text,
  city text not null,
  state text not null,
  pincode text not null check (pincode ~ '^[0-9]{6}$'),
  landmark text,
  country text not null default 'India',
  latitude double precision,
  longitude double precision,
  accuracy_meters double precision,
  source text not null default 'manual' check (source in ('manual','device')),
  captured_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint staging_listing_addresses_coordinate_pair_check check (
    (latitude is null and longitude is null)
    or (latitude between -90 and 90 and longitude between -180 and 180)
  )
);

create index if not exists staging_listing_addresses_seller_idx
  on public.staging_listing_addresses (seller_id, updated_at desc);
create index if not exists staging_listing_addresses_pincode_idx
  on public.staging_listing_addresses (pincode);

alter table public.staging_listing_addresses enable row level security;
revoke all on table public.staging_listing_addresses from anon, authenticated;

comment on table public.staging_listing_addresses is
  'Private seller pickup/dispatch address shared by mobile, future web and admin operations; never expose through guest/public listing APIs.';
