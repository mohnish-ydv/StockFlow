-- StockFlow v1.4.0
-- Guest marketplace reads + full private seller stock addresses.
-- Mobile, future web and admin continue to share the same Postgres source of truth.

alter table public.staging_listing_locations
  alter column latitude drop not null,
  alter column longitude drop not null;

alter table public.staging_listing_locations
  add column if not exists address_line1 text,
  add column if not exists street text,
  add column if not exists locality text,
  add column if not exists district text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists pincode text,
  add column if not exists landmark text,
  add column if not exists country text not null default 'India',
  add column if not exists geocoded_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'staging_listing_locations_coordinate_pair_check'
      and conrelid = 'public.staging_listing_locations'::regclass
  ) then
    alter table public.staging_listing_locations
      add constraint staging_listing_locations_coordinate_pair_check
      check (
        (latitude is null and longitude is null)
        or
        (latitude between -90 and 90 and longitude between -180 and 180)
      );
  end if;
end $$;

create index if not exists staging_listing_locations_pincode_idx
  on public.staging_listing_locations (pincode)
  where pincode is not null;

comment on table public.staging_listing_locations is
  'Private operational pickup/dispatch location. Exact address/GPS must never be exposed by public feed/listing APIs.';
comment on column public.staging_listing_locations.address_line1 is
  'Private house/shop/building component for StockFlow fulfilment operations.';
comment on column public.staging_listing_locations.street is
  'Private street/road component for StockFlow fulfilment operations.';
comment on column public.staging_listing_locations.locality is
  'Private area/locality component for StockFlow fulfilment operations.';
