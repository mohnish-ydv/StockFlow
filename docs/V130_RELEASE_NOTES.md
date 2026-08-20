# StockFlow v1.3.0 release notes

Build: `1.3.0+22`

## Fixed from device screenshots
- AI listing assistant moved from the retired staging model to `gemini-3.5-flash-lite`, configured server-side.
- Location flow now requests foreground permission when the seller taps **Use current location**, then separately handles disabled device Location services and permanently denied app permission.

## New mediated commercial flow
- Listing detail uses **I’m interested** instead of opening buyer/seller messaging.
- Buyer interest is stored as a protected deal request and appears in the seller Deals inbox and admin Deals desk.
- Admin can coordinate the buyer and seller without exposing their contact details to each other.
- Buyer may unlock a listing-specific protected chat after acknowledging the promise-fee terms.
- Current promise-fee capture is staging-only and charges no real money.
- Conversations and offers are database-blocked without an active chat entitlement.
- Common phone-number-shaped contact details, emails, social handles and external links are blocked in public listing text and protected chat. The latest precision rules avoid blocking ordinary product phrases such as “mobile phone”.

## Shared mobile + web backend
- Android, iOS, admin and future web clients share one Supabase/Postgres data model and API layer.
- `source_channel` records the originating client without duplicating business entities.
- `auth_subject` provides the production identity/JWT migration bridge to the same user records.

## Security and operations
- v3 application gateway: action allow-list, 64 KB body cap, rate limiting, trace IDs, security events and server-side authorization.
- Database-enforced chat/offer entitlement and listing/chat contact-exchange guards.
- Exact seller/listing GPS is stored outside public listing rows and returned only to authorized admin analytics.
- Admin analytics include deals, promise fees, product interest, locations, AI health and diagnostics.
- See `docs/PRODUCTION_SECURITY_CHECKLIST.md` for the production WAF/CDN, JWT, payment-webhook, secret-rotation and legacy-endpoint cut-over checklist.
