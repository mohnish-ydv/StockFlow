-- StockFlow v1.5: moderated listings, richer seller verification, media, user ops.

alter table public.staging_users
  add column if not exists account_status text not null default 'active',
  add column if not exists admin_note text,
  add column if not exists last_seen_at timestamptz;

alter table public.staging_users drop constraint if exists staging_users_account_status_check;
alter table public.staging_users add constraint staging_users_account_status_check
  check (account_status in ('active','suspended','banned'));

alter table public.staging_seller_applications
  add column if not exists legal_name text,
  add column if not exists gstin text,
  add column if not exists pan text,
  add column if not exists udyam_number text,
  add column if not exists website text,
  add column if not exists years_in_business integer,
  add column if not exists primary_categories text[] not null default '{}',
  add column if not exists warehouse_count integer,
  add column if not exists monthly_stock_volume text,
  add column if not exists contact_designation text;

alter table public.staging_seller_applications drop constraint if exists staging_seller_applications_years_check;
alter table public.staging_seller_applications add constraint staging_seller_applications_years_check
  check (years_in_business is null or (years_in_business between 0 and 150));
alter table public.staging_seller_applications drop constraint if exists staging_seller_applications_warehouse_check;
alter table public.staging_seller_applications add constraint staging_seller_applications_warehouse_check
  check (warehouse_count is null or (warehouse_count between 0 and 10000));

alter table public.staging_listings
  add column if not exists moderation_note text,
  add column if not exists moderated_at timestamptz,
  add column if not exists moderated_by uuid references public.staging_users(id) on delete set null,
  add column if not exists submitted_at timestamptz not null default now(),
  add column if not exists review_round integer not null default 1,
  add column if not exists last_resubmitted_at timestamptz;

create index if not exists staging_listings_status_submitted_idx
  on public.staging_listings(status, submitted_at desc);
create index if not exists staging_listings_moderated_by_idx
  on public.staging_listings(moderated_by) where moderated_by is not null;

create table if not exists public.staging_listing_media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  seller_id uuid not null references public.staging_users(id) on delete cascade,
  media_type text not null check (media_type in ('image','video')),
  url text not null,
  storage_path text,
  mime_type text not null,
  sort_order integer not null default 0 check (sort_order between 0 and 20),
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  duration_seconds numeric,
  created_at timestamptz not null default now(),
  unique(listing_id, sort_order),
  check (
    (media_type='image' and size_bytes <= 5242880 and duration_seconds is null)
    or
    (media_type='video' and size_bytes <= 10485760 and duration_seconds is not null and duration_seconds > 0 and duration_seconds <= 30)
  )
);
create index if not exists staging_listing_media_listing_idx on public.staging_listing_media(listing_id, sort_order);
create index if not exists staging_listing_media_seller_idx on public.staging_listing_media(seller_id, created_at desc);
alter table public.staging_listing_media enable row level security;

create table if not exists public.staging_listing_review_history (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  status listing_status not null,
  note text,
  actor_id uuid references public.staging_users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists staging_listing_review_history_listing_idx on public.staging_listing_review_history(listing_id, created_at desc);
create index if not exists staging_listing_review_history_actor_idx on public.staging_listing_review_history(actor_id) where actor_id is not null;
alter table public.staging_listing_review_history enable row level security;

create table if not exists public.staging_listing_reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  reporter_id uuid references public.staging_users(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')),
  admin_note text,
  resolved_by uuid references public.staging_users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists staging_listing_reports_status_idx on public.staging_listing_reports(status, created_at desc);
create index if not exists staging_listing_reports_listing_idx on public.staging_listing_reports(listing_id, created_at desc);
create index if not exists staging_listing_reports_reporter_idx on public.staging_listing_reports(reporter_id) where reporter_id is not null;
create index if not exists staging_listing_reports_resolved_idx on public.staging_listing_reports(resolved_by) where resolved_by is not null;
alter table public.staging_listing_reports enable row level security;

create or replace function public.stockflow_force_new_listing_review()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Legacy/core clients used to request active on insert. New stock must always
  -- enter moderation first. Existing approved listings are not changed.
  if new.status = 'active' then
    new.status := 'pending_review';
  end if;
  new.moderation_note := null;
  new.moderated_at := null;
  new.moderated_by := null;
  new.submitted_at := coalesce(new.submitted_at, now());
  return new;
end;
$$;

drop trigger if exists staging_force_new_listing_review on public.staging_listings;
create trigger staging_force_new_listing_review
before insert on public.staging_listings
for each row execute function public.stockflow_force_new_listing_review();

create or replace function public.stockflow_listing_media_limit_guard()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  total_count integer;
  video_count integer;
begin
  select count(*) into total_count from public.staging_listing_media
    where listing_id = new.listing_id and id is distinct from new.id;
  if total_count >= 8 then
    raise exception 'A listing can contain at most 8 media items.' using errcode='22023';
  end if;
  if new.media_type = 'video' then
    select count(*) into video_count from public.staging_listing_media
      where listing_id = new.listing_id and media_type='video' and id is distinct from new.id;
    if video_count >= 2 then
      raise exception 'A listing can contain at most 2 videos.' using errcode='22023';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists staging_listing_media_limit_guard on public.staging_listing_media;
create trigger staging_listing_media_limit_guard
before insert or update on public.staging_listing_media
for each row execute function public.stockflow_listing_media_limit_guard();

-- Public staging media bucket remains usable for product imagery/video, while
-- write authorization is still enforced by the upload Edge Function.
update storage.buckets
set file_size_limit = 12582912,
    allowed_mime_types = array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']::text[]
where id = 'staging-listings';

insert into public.app_settings(key,value,updated_at)
values (
  'marketplace_home_banner',
  jsonb_build_object(
    'enabled', true,
    'eyebrow', 'STOCKFLOW MARKETPLACE',
    'title', 'Clear surplus stock with less friction',
    'body', 'Post once, get reviewed, and let StockFlow coordinate serious buyer interest.',
    'cta', 'Post stock'
  ),
  now()
)
on conflict (key) do update set value=excluded.value,updated_at=now();
