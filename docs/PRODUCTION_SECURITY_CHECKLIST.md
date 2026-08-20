# StockFlow production security checklist

The v1.3 staging build adds database-enforced mediated deals, rate limits, contact-exchange blocking, private GPS storage, server-side Gemini access, and security telemetry. These controls reduce abuse risk, but no internet-facing application can be guaranteed “hack-proof”. Before production launch, complete the following hardening work.

## Identity and sessions
- Move staging OTP/session authentication to Supabase Auth or another production identity provider.
- Map the provider subject to `staging_users.auth_subject` (rename the staging tables during the production cut-over if desired) so Android, iOS and the future website use the same user identity and business records.
- Use short-lived signed access tokens/JWTs, secure refresh/session rotation, server-side role checks, revocation, and MFA for administrators.
- Remove fixed staging OTPs and staging admin credentials before launch.

## API edge and DDoS controls
- Expose one production API hostname only; retire or firewall the legacy `stockflow-staging-api` route after all clients have migrated to the v3 gateway.
- Put the production website/API behind a managed CDN/WAF/DDoS service and enable bot/rate-limit rules at the edge in addition to the database-backed application limits.
- Keep request-size limits, action allowlists, origin allowlists for browsers, security headers, and abuse telemetry enabled.
- Alert on sustained `staging_security_events` rate-limit/contact-circumvention spikes.

## Database
- Keep private tables behind server-side access. Exact listing coordinates must never be returned by the public feed/listing API.
- When production JWT auth is enabled, replace the staging service-role-only pattern with explicit RLS policies keyed to the authenticated subject/role.
- Keep database triggers that require a chat entitlement for conversations/offers/messages and that block contact details in public listing text.
- Maintain tested backups, point-in-time recovery where available, migration reviews, and periodic security/performance advisor checks.

## Promise fee / payments
- The current promise fee is staging-only and does not charge real money.
- Integrate a compliant payment provider server-side. Never unlock chat from a client-side “payment success” flag.
- Verify signed provider webhooks on the backend, enforce idempotency, store provider references, and grant `staging_chat_entitlements` only after server-confirmed capture.
- Keep legal copy and refund exceptions aligned with the final provider, jurisdiction and client policy.

## Messaging abuse prevention
- Keep contact/external-link blocking at both API and database layers.
- Add moderation/report/block tooling, spam velocity limits, attachment scanning before enabling chat attachments, and review escalation for repeated bypass attempts.
- Do not expose buyer/seller phone, email or exact GPS data to the opposite party by default.

## AI and secrets
- Gemini credentials stay server-side only; never compile them into Flutter or JavaScript bundles.
- Rotate the development Gemini credential before production because it was shared during development.
- Restrict the replacement credential to the minimum required Google service/project where possible and monitor usage/cost anomalies.

## Mobile and web release
- Android should request foreground location only when the seller taps “Use current location”; do not request background location for this feature.
- The future website should call the same backend contracts and database rather than create a second marketplace data store.
- Run dependency/SAST/secret scanning in CI, keep dependencies patched, and test authorization with modified clients—not only through the intended UI.
