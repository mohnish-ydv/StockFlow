-- StockFlow v1.3 performance hardening for new mediated-deal foreign keys.
create index if not exists staging_chat_entitlements_conversation_idx
  on public.staging_chat_entitlements(conversation_id)
  where conversation_id is not null;
create index if not exists staging_chat_entitlements_payment_idx
  on public.staging_chat_entitlements(payment_id)
  where payment_id is not null;
create index if not exists staging_deal_history_actor_idx
  on public.staging_deal_status_history(actor_id)
  where actor_id is not null;
create index if not exists staging_security_events_user_idx
  on public.staging_security_events(user_id)
  where user_id is not null;
