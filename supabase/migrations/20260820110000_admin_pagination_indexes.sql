-- StockFlow v1.5 admin pagination/query hardening.
-- These indexes match the default newest-first ordering used by admin pages.

create index if not exists staging_users_created_at_idx
  on public.staging_users(created_at desc);

create index if not exists staging_seller_applications_created_at_idx
  on public.staging_seller_applications(created_at desc);

create index if not exists staging_listings_submitted_at_idx
  on public.staging_listings(submitted_at desc);

create index if not exists staging_listing_reports_created_at_idx
  on public.staging_listing_reports(created_at desc);

create index if not exists staging_deal_requests_created_at_idx
  on public.staging_deal_requests(created_at desc);

create index if not exists staging_orders_created_at_idx
  on public.staging_orders(created_at desc);

-- Admin deal-page enrichment fetches payment history by deal id and newest event.
create index if not exists staging_promise_fee_deal_time_idx
  on public.staging_promise_fee_payments(deal_request_id, created_at desc);

-- Queue counters and per-page activity enrichment.
create index if not exists staging_users_account_status_created_idx
  on public.staging_users(account_status, created_at desc);

create index if not exists staging_seller_applications_status_created_idx
  on public.staging_seller_applications(status, created_at desc);

create index if not exists staging_seller_applications_user_idx
  on public.staging_seller_applications(user_id);

create index if not exists staging_listings_seller_id_idx
  on public.staging_listings(seller_id);

create index if not exists staging_orders_buyer_created_idx
  on public.staging_orders(buyer_id, created_at desc);

create index if not exists staging_orders_seller_created_idx
  on public.staging_orders(seller_id, created_at desc);

create index if not exists staging_users_seller_status_created_idx
  on public.staging_users(seller_status, created_at desc);
