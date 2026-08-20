# StockFlow

StockFlow is a mobile-first B2B marketplace for surplus, overstock and dead-stock inventory. **v1.5.0** adds moderated listings, multi-photo/video inventory, a professional marketplace operations console, richer seller verification, strict sign-in semantics, an approximate 10 km public stock-location map and a more mature classifieds-style discovery experience. Android, iOS, the admin panel and the future StockFlow website share one Supabase/Postgres source of truth.

## v1.5.0 — moderated marketplace + media + admin operations

- Guest-first marketplace browsing with compact search/location/category discovery.
- Configurable cobalt StockFlow home banner.
- New listings are `pending_review` until admin approval.
- Admin rejection reason is visible to seller; rejected stock can be fixed and resubmitted.
- Up to 8 media items/listing, up to 2 videos, video <=30 sec / 10 MB, image <=5 MB.
- Listing detail shows multi-media gallery and approximate 10 km public area map; exact GPS/private address stays operational-only.
- Seller verification adds optional GSTIN, PAN, Udyam and operating-profile fields.
- Strict Sign in vs Create account behavior prevents silent account creation.
- Admin console controls listings/media/sellers/users/deals/orders/reports/diagnostics.
- Same backend contracts are intended for the future website.

See `docs/V150_MARKETPLACE_MODERATION_MEDIA_ADMIN.md`.

## Mediated buyer → seller deal flow

The v1.3 commercial model remains intact:

1. Buyer opens a listing and taps **I’m interested**.
2. StockFlow creates a protected deal request for seller/admin operations without exposing direct buyer contact details.
3. The operations/admin team can coordinate both sides.
4. If the buyer wants direct in-app negotiation, StockFlow can show the listing-specific **promise fee**.
5. After successful payment, a protected chat entitlement is created.
6. Phone numbers, emails, social handles and external links are blocked from being exchanged through protected chat/listing content.

The current promise-fee capture is **staging only** and does not charge real money. A production payment provider and signed server-to-server webhook are required before real-money release.

## Seller posting

The four-step posting flow stays intentionally short:

1. Photo + title + optional one-line note → **Generate with AI**
2. Price & stock
3. **Fulfilment & address**
4. Review & submit for admin approval

Gemini runs server-side using the configured model. No Gemini credential ships in the APK, static admin or repository source.

## Security architecture

This release keeps the existing security boundaries and adds safer guest reads:

- `stockflow-api-v3` gateway with action allow-listing, request-size limits, rate limiting, trace IDs and abuse events.
- Guest `feed`, `listing` and `categories` are explicit read-only API paths with a field allow-list.
- Private seller addresses and exact GPS are not part of public listing responses.
- RLS/private-table grants prevent direct client reads of operational address records.
- Client apps never receive service-role credentials.
- Database triggers prevent buyer/seller conversation or offer creation without an active chat entitlement.
- Database + API checks block common contact-exchange attempts.
- Admin role checks run server-side.
- Gemini key remains server-side.
- Client diagnostics/security events are available to the admin control centre.
- CI validates secret leakage, guest-safe feeds, Android/iOS foreground location configuration and the full-address source contract.

A public internet service cannot be guaranteed “hack-proof”. Before production, use production JWT/Supabase Auth, rotate development credentials, connect signed payment webhooks, and place the public API/custom domain behind a managed CDN/WAF/DDoS protection layer.

## Marketplace navigation

**Home → Deals → Sell → My stock → Account**

Guests can use **Home**, Search/Listing Detail and the guest **Account** page without signing in.

## Design handoff

Figma: https://www.figma.com/design/AUPjv6fCbjrOwkUhViuT8U

See `docs/V110_REFERENCE_QUALITY_REBUILD.md`, `docs/V120_CLIENT_REQUIREMENTS_FINAL.md`, `docs/V130_MEDIATED_DEALS_SECURITY_REBUILD.md`, and `docs/V140_GUEST_BROWSING_FULL_ADDRESS.md`.

## Staging credentials

Development/testing only:

- App OTP adapter: `123456`
- Admin staging mobile: `9999999999`
- Admin OTP: `246810`

Production SMS/auth, payment and logistics providers replace staging adapters after final client acceptance.

## Admin frontend

The admin site ships at `docs/admin/index.html` and deploys through `.github/workflows/admin-pages.yml`. GitHub Pages requires **Settings → Pages → Source → GitHub Actions** before first deployment. See `ADMIN_ACCESS.md`.

## CI

`.github/workflows/mobile.yml` performs package preflight, dependency/secret guards, live guest-feed and backend smoke checks, UI/security/address regression guards, `flutter analyze --fatal-infos`, tests, Android APK build/sanity checks and unsigned iOS release compile.

Artifacts:

- `StockFlow-v1.5.0-Marketplace-Moderation-Android-Release`
- `StockFlow-v1.5.0-Marketplace-Moderation-iOS-Unsigned-App`
