# StockFlow v1.3 — Mediated Deals & Security Rebuild

## Product decision

Direct buyer/seller messaging is no longer the default entry point. Listing detail exposes one primary commercial action: **I’m interested**. The backend creates a deal request and the seller receives a protected interest state in Deals without buyer contact information. StockFlow operations can coordinate both parties in the admin deal desk.

## Promise-fee protected chat

A buyer may unlock in-app chat for one deal after acknowledging the displayed non-refundable promise-fee terms. In staging, the capture adapter creates a test payment and explicitly charges no real money. Production must replace this with a payment provider plus server-verified webhook before entitlements are granted.

Chat entitlement is enforced in Postgres, not only in Flutter. Conversation creation and structured offers fail without an active entitlement. Text messages are filtered at client, API gateway and database trigger layers for common phone numbers, email addresses, social handles and external links.

## Website-ready data model

Android, iOS, admin and the future website share one Supabase/Postgres system. Deal requests contain `source_channel`; business entities are not duplicated per platform. `staging_users.auth_subject` is reserved to bind a future Supabase Auth/JWT identity to the same marketplace user row.

## Location

Foreground permission is requested only after the seller explicitly taps **Use current location**. Permission-denied-forever and Location-services-disabled states have separate remediation actions. Coordinates are kept in `staging_listing_locations`; public listing responses continue to use city/state only.

## AI listing assistant

The server-side extension reads the model from `app_settings.stockflow_ai` and defaults to `gemini-3.5-flash-lite`. Responses use structured JSON for suggested title, description and an allow-listed category. Provider credentials remain server-side.

## Abuse and security controls

- v3 API gateway action allow-list and 64 KB request-body cap.
- Per-identity database-backed rate limits for login/read/write/chat/AI/interest/payment flows.
- RLS on protected tables, service-role access only from backend functions.
- DB entitlement triggers so a modified APK cannot bypass paid chat by calling legacy action names.
- Contact-exchange filtering in protected chat.
- Security-event and client-error telemetry with trace/reference IDs.
- Exact GPS is admin-only.
- CI blocks common secret patterns.

No public service is literally hack-proof. Production should additionally use a custom domain behind a managed CDN/WAF/DDoS service, production JWT/Supabase Auth, rotated secrets, signed payment webhooks, backups, monitoring and incident response.
