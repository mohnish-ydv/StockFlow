-- StockFlow v1.3 defence in depth: prevent sellers from publishing off-platform
-- contact details inside public listing fields, even if a modified client calls
-- the legacy core API directly.

create or replace function public.stockflow_guard_listing_contact_exchange()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_text text;
  v_digits text;
begin
  v_text := lower(concat_ws(' ', coalesce(new.title,''), coalesce(new.description,''), coalesce(new.brand,'')));
  v_digits := regexp_replace(v_text, '[^0-9]', '', 'g');
  if v_text ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}'
     or v_text ~* '(https?://|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)'
     or v_text ~* '(^|[^a-z])(whatsapp|telegram|instagram|snapchat|phone|mobile|call me|email me)([^a-z]|$)'
     or v_digits ~ '[6-9][0-9]{9}' then
    raise exception 'Contact details and external links are not allowed in public listings. Keep buyer communication inside StockFlow.' using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_stockflow_guard_listing_contact_exchange on public.staging_listings;
create trigger trg_stockflow_guard_listing_contact_exchange
before insert or update of title, description, brand on public.staging_listings
for each row execute function public.stockflow_guard_listing_contact_exchange();
