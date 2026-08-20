create index if not exists staging_client_logs_user_idx on public.staging_client_logs(user_id);
create index if not exists staging_listing_events_user_idx on public.staging_listing_events(user_id);
