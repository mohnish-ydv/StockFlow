create table if not exists public.staging_listing_locations (
  listing_id uuid primary key references public.staging_listings(id) on delete cascade,
  seller_id uuid not null references public.staging_users(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_meters double precision,
  source text not null default 'device' check (source in ('device','manual','unknown')),
  captured_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists staging_listing_locations_seller_idx on public.staging_listing_locations(seller_id);

create table if not exists public.staging_listing_events (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  user_id uuid references public.staging_users(id) on delete set null,
  event_type text not null check (event_type in ('view','chat','offer','cart','checkout')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists staging_listing_events_listing_time_idx on public.staging_listing_events(listing_id, created_at desc);
create index if not exists staging_listing_events_type_time_idx on public.staging_listing_events(event_type, created_at desc);

create table if not exists public.staging_client_logs (
  id uuid primary key default gen_random_uuid(),
  event_id text not null unique,
  user_id uuid references public.staging_users(id) on delete set null,
  severity text not null default 'error' check (severity in ('info','warning','error','fatal')),
  code text not null,
  message text not null,
  context jsonb not null default '{}'::jsonb,
  app_version text,
  platform text,
  created_at timestamptz not null default now()
);
create index if not exists staging_client_logs_time_idx on public.staging_client_logs(created_at desc);
create index if not exists staging_client_logs_code_time_idx on public.staging_client_logs(code, created_at desc);

create table if not exists public.staging_ai_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.staging_users(id) on delete cascade,
  model text not null,
  input_title text not null,
  input_note text,
  output_category text,
  status text not null check (status in ('success','failed','rate_limited')),
  latency_ms integer,
  created_at timestamptz not null default now()
);
create index if not exists staging_ai_requests_user_time_idx on public.staging_ai_requests(user_id, created_at desc);

alter table public.staging_listing_locations enable row level security;
alter table public.staging_listing_events enable row level security;
alter table public.staging_client_logs enable row level security;
alter table public.staging_ai_requests enable row level security;

create or replace function public.stockflow_get_gemini_key()
returns text
language sql
security definer
set search_path = vault, public
as $$
  select decrypted_secret
  from vault.decrypted_secrets
  where name = 'stockflow_gemini_api_key'
  order by created_at desc
  limit 1
$$;

revoke all on function public.stockflow_get_gemini_key() from public;
revoke all on function public.stockflow_get_gemini_key() from anon;
revoke all on function public.stockflow_get_gemini_key() from authenticated;
grant execute on function public.stockflow_get_gemini_key() to service_role;
