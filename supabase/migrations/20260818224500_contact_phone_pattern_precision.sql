-- Detect phone-shaped sequences without concatenating unrelated product numbers.

create or replace function public.stockflow_guard_message_insert()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_conversation record;
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
    if v_text ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}'
       or v_text ~* '(https?://|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)'
       or v_text ~* '(^|[^a-z])(whatsapp|telegram|instagram|snapchat)([^a-z]|$)'
       or v_text ~* '(^|[^a-z])(call|contact|text|message|dm|ping)[[:space:]]+(me|us)([^a-z]|$)'
       or v_text ~* '(^|[^0-9])(\+?91[[:space:].-]?)?[6-9]([[:space:].-]?[0-9]){9}([^0-9]|$)' then
      raise exception 'Contact details and external links are blocked in StockFlow chat. Keep the deal inside StockFlow.' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.stockflow_guard_listing_contact_exchange()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_text text;
begin
  v_text := lower(concat_ws(' ', coalesce(new.title,''), coalesce(new.description,''), coalesce(new.brand,'')));
  if v_text ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}'
     or v_text ~* '(https?://|www\.|wa\.me|t\.me|telegram\.me|instagram\.com|facebook\.com)'
     or v_text ~* '(^|[^a-z])(whatsapp|telegram|instagram|snapchat)([^a-z]|$)'
     or v_text ~* '(^|[^a-z])(call|contact|text|message|dm|ping)[[:space:]]+(me|us)([^a-z]|$)'
     or v_text ~* '(^|[^0-9])(\+?91[[:space:].-]?)?[6-9]([[:space:].-]?[0-9]){9}([^0-9]|$)' then
    raise exception 'Contact details and external links are not allowed in public listings. Keep buyer communication inside StockFlow.' using errcode = '22023';
  end if;
  return new;
end;
$$;
