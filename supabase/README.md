# Supabase backend state

Remote project ref: `zuzihcjpjwhrlfeushwd` (`ap-northeast-1`).

Core applied backend milestones include the existing Part 1 + Part 2 marketplace/commerce migrations plus the v1.2 client-final additions:

- `stockflow_client_final_features`
- `seller_approval_timestamps`
- `seller_approval_trigger_search_path_hardening`
- `client_feature_fk_index_hardening`

Current relevant Edge Functions:

- `stockflow-staging-api` — marketplace/auth/chat/offer/cart/order API
- `stockflow-staging-upload` — approved-seller image upload
- `stockflow-admin` — legacy/admin endpoint
- `stockflow-extensions` — v1.2 AI listing assist, private GPS attachment, event analytics, client diagnostics and admin analytics

## v1.2 private operational data

- `staging_listing_locations` — exact listing GPS; RLS enabled, no client read policy
- `staging_listing_events` — view/chat/offer/cart/checkout analytics
- `staging_client_logs` — traceable incident/error references
- `staging_ai_requests` — AI usage/success telemetry
- `staging_users.seller_approved_at` — approval-time analytics

The Gemini credential is stored server-side and fetched only inside the service-role Edge Function path. It must never be copied into Flutter, static web source, Git history, CI source, or documentation.

RLS-with-no-policy on private staging tables is intentional: buyer/seller apps do not query these tables directly; the server-side Edge Function mediates access. Exact coordinates are returned only by the admin analytics action after backend admin-role verification.

Before production, rotate the development Gemini credential, switch staging OTP/session adapters to the approved production auth design, and apply the same migration/function sources to the client-owned production project.


## v1.3 mediated deal backend

Apply `migrations/20260818214500_mediated_deals_web_security.sql`, then deploy `stockflow-extensions` and `stockflow-api-v3`. Mobile, admin and future web clients share this project/schema. `stockflow-api-v3` is the public application gateway; protected chat entitlement and anti-contact rules are also enforced in database triggers as a defence-in-depth layer.

v1.3 follow-up hardening migrations:
- `20260818222000_listing_contact_exchange_hardening.sql` — public listing contact-exchange DB guard.
- `20260818223000_mediated_deal_fk_indexes.sql` — covering indexes for mediated-deal foreign keys.
- `20260818224000_contact_filter_precision.sql` — keeps contact blocking precise so legitimate terms such as “mobile phone” are not false positives.
- `20260818224500_contact_phone_pattern_precision.sql` — detects phone-shaped sequences without concatenating unrelated product numbers.

## v1.5 admin pagination hardening

Apply `migrations/20260820110000_admin_pagination_indexes.sql` with the v1.5 moderation schema. The admin users, seller applications, listings, reports and mediated-deals endpoints now use bounded server-side pages with exact total counts; the operations console renders Previous/Next controls instead of relying on silent 300/500/1000-row caps. The migration adds newest-first and queue/activity indexes used by those admin queries.
