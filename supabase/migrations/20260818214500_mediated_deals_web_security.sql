-- StockFlow v1.3: mediated deal flow, paid chat entitlement, website-ready identity mapping,
-- database-enforced anti-bypass controls, and rate-limit/security telemetry.

alter table public.staging_users
  add column if not exists auth_subject uuid,
  add column if not exists client_origin text not null default 'mobile';
create unique index if not exists staging_users_auth_subject_uidx
  on public.staging_users(auth_subject) where auth_subject is not null;

create table if not exists public.staging_deal_requests (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  buyer_id uuid not null references public.staging_users(id) on delete cascade,
  seller_id uuid not null references public.staging_users(id) on delete cascade,
  requested_qty integer not null default 1 check (requested_qty > 0),
  status text not null default 'pending_admin' check (status in (
    'pending_admin','contacting','awaiting_fee','chat_unlocked','in_negotiation','converted','closed','cancelled'
  )),
  source_channel text not null default 'android' check (source_channel in ('android','ios','web','admin','unknown')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists staging_deal_requests_active_unique
  on public.staging_deal_requests(listing_id,buyer_id)
  where status not in ('closed','cancelled','converted');
create index if not exists staging_deal_requests_buyer_time_idx on public.staging_deal_requests(buyer_id, created_at desc);
create index if not exists staging_deal_requests_seller_time_idx on public.staging_deal_requests(seller_id, created_at desc);
create index if not exists staging_deal_requests_status_time_idx on public.staging_deal_requests(status, created_at desc);

create table if not exists public.staging_promise_fee_payments (
  id uuid primary key default gen_random_uuid(),
  deal_request_id uuid not null references public.staging_deal_requests(id) on delete cascade,
  buyer_id uuid not null references public.staging_users(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'INR',
  provider text not null default 'staging',
  provider_reference text,
  status text not null default 'pending' check (status in ('pending','captured','failed','refunded','void')),
  non_refundable_ack boolean not null default false,
  created_at timestamptz not null default now(),
  captured_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists staging_promise_fee_buyer_time_idx on public.staging_promise_fee_payments(buyer_id, created_at desc);
create unique index if not exists staging_promise_fee_one_capture_idx
  on public.staging_promise_fee_payments(deal_request_id) where status = 'captured';

create table if not exists public.staging_chat_entitlements (
  id uuid primary key default gen_random_uuid(),
  deal_request_id uuid not null unique references public.staging_deal_requests(id) on delete cascade,
  listing_id uuid not null references public.staging_listings(id) on delete cascade,
  buyer_id uuid not null references public.staging_users(id) on delete cascade,
  seller_id uuid not null references public.staging_users(id) on delete cascade,
  payment_id uuid references public.staging_promise_fee_payments(id) on delete set null,
  conversation_id uuid references public.staging_conversations(id) on delete set null,
  status text not null default 'active' check (status in ('active','revoked','expired')),
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists staging_chat_entitlement_pair_uidx
  on public.staging_chat_entitlements(listing_id,buyer_id,seller_id)
  where status = 'active';
create index if not exists staging_chat_entitlement_buyer_idx on public.staging_chat_entitlements(buyer_id, status);
create index if not exists staging_chat_entitlement_seller_idx on public.staging_chat_entitlements(seller_id, status);

create table if not exists public.staging_deal_status_history (
  id uuid primary key default gen_random_uuid(),
  deal_request_id uuid not null references public.staging_deal_requests(id) on delete cascade,
  status text not null,
  actor_id uuid references public.staging_users(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);
create index if not exists staging_deal_history_request_time_idx on public.staging_deal_status_history(deal_request_id, created_at);

create table if not exists public.staging_rate_limit_buckets (
  key_hash text not null,
  action_group text not null,
  window_start timestamptz not null,
  hits integer not null default 0 check (hits >= 0),
  updated_at timestamptz not null default now(),
  primary key (key_hash, action_group, window_start)
);
create index if not exists staging_rate_limit_updated_idx on public.staging_rate_limit_buckets(updated_at desc);

create table if not exists public.staging_security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.staging_users(id) on delete set null,
  category text not null,
  action_name text,
  key_hash text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists staging_security_events_time_idx on public.staging_security_events(created_at desc);
create index if not exists staging_security_events_category_time_idx on public.staging_security_events(category, created_at desc);

alter table public.staging_deal_requests enable row level security;
alter table public.staging_promise_fee_payments enable row level security;
alter table public.staging_chat_entitlements enable row level security;
alter table public.staging_deal_status_history enable row level security;
alter table public.staging_rate_limit_buckets enable row level security;
alter table public.staging_security_events enable row level security;

insert into public.app_settings(key,value,updated_at)
values
  ('stockflow_ai', jsonb_build_object('model','gemini-3.5-flash-lite'), now()),
  ('promise_fee', jsonb_build_object('amount',49,'currency','INR','stagingCaptureEnabled',true), now())
on conflict (key) do update set value = excluded.value, updated_at = excluded.updated_at;

create or replace function public.stockflow_rate_limit(
  p_key_hash text,
  p_action_group text,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_bucket timestamptz;
  v_hits integer;
begin
  if p_key_hash is null or length(p_key_hash) < 8 or p_limit < 1 or p_window_seconds < 1 then
    return false;
  end if;
  v_bucket := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  insert into public.staging_rate_limit_buckets(key_hash, action_group, window_start, hits, updated_at)
  values (p_key_hash, left(coalesce(p_action_group,'default'),80), v_bucket, 1, now())
  on conflict (key_hash, action_group, window_start)
  do update set hits = public.staging_rate_limit_buckets.hits + 1, updated_at = now()
  returning hits into v_hits;
  return v_hits <= p_limit;
end;
$$;
revoke all on function public.stockflow_rate_limit(text,text,integer,integer) from public, anon, authenticated;
grant execute on function public.stockflow_rate_limit(text,text,integer,integer) to service_role;

create or replace function public.stockflow_has_chat_entitlement(
  p_listing_id uuid,
  p_buyer_id uuid,
  p_seller_id uuid
) returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.staging_chat_entitlements e
    where e.listing_id = p_listing_id
      and e.buyer_id = p_buyer_id
      and e.seller_id = p_seller_id
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
  )
$$;
revoke all on function public.stockflow_has_chat_entitlement(uuid,uuid,uuid) from public, anon, authenticated;
grant execute on function public.stockflow_has_chat_entitlement(uuid,uuid,uuid) to service_role;

create or replace function public.stockflow_guard_conversation_insert()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if not public.stockflow_has_chat_entitlement(new.listing_id, new.buyer_id, new.seller_id) then
    raise exception 'Paid chat is not unlocked for this deal. Send an interest request first.' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_stockflow_guard_conversation_insert on public.staging_conversations;
create trigger trg_stockflow_guard_conversation_insert
before insert on public.staging_conversations
for each row execute function public.stockflow_guard_conversation_insert();

create or replace function public.stockflow_guard_offer_insert()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if not public.stockflow_has_chat_entitlement(new.listing_id, new.buyer_id, new.seller_id) then
    raise exception 'Offers are available only after protected chat is unlocked.' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_stockflow_guard_offer_insert on public.staging_offers;
create trigger trg_stockflow_guard_offer_insert
before insert on public.staging_offers
for each row execute function public.stockflow_guard_offer_insert();

create or replace function public.stockflow_guard_message_insert()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_conversation record;
  v_digits text;
  v_text text;
begin
  if new.message_type not in ('text','offer') then
    return new;
  end if;

  select listing_id,buyer_id,seller_id into v_conversation
  from public.staging_conversations where id = new.conversation_id;

  if v_conversation is null or not public.stockflow_has_chat_entitlement(v_conversation.listing_id, v_conversation.buyer_id, v_conversation.seller_id) then
    raise exception 'Protected chat is locked for this deal.' using errcode = '42501';
  end if;

  if new.message_type = 'text' then
    v_text := lower(coalesce(new.body,''));
    v_digits := regexp_replace(v_text, '[^0-9]', '', 'g');
    if v_text ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}'
       or v_text ~* '(https?://|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)'
       or v_text ~* '(^|[^a-z])(whatsapp|telegram|instagram|snapchat|phone|mobile|call me|email me)([^a-z]|$)'
       or v_digits ~ '[6-9][0-9]{9}' then
      raise exception 'Contact details and external links are blocked in StockFlow chat. Keep the deal inside StockFlow.' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_stockflow_guard_message_insert on public.staging_messages;
create trigger trg_stockflow_guard_message_insert
before insert on public.staging_messages
for each row execute function public.stockflow_guard_message_insert();

-- Keep rate-limit buckets bounded without requiring a scheduler.
create or replace function public.stockflow_prune_rate_limits()
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.staging_rate_limit_buckets where updated_at < now() - interval '2 days'
$$;
revoke all on function public.stockflow_prune_rate_limits() from public, anon, authenticated;
grant execute on function public.stockflow_prune_rate_limits() to service_role;
