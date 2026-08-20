# StockFlow v1.5.0 — Marketplace Moderation, Media & Operations

Build: `1.5.0+26`

v1.5.0 turns StockFlow from a listing demo into a moderated marketplace workflow. The mobile experience takes interaction cues from mature classifieds products (dense discovery, category shortcuts, a promotional surface, seller trust context and approximate location) while retaining StockFlow's own cobalt visual system and mediated-deal model.

## Buyer experience

- Guest users can browse the marketplace and listing details without creating an account.
- Home has a compact location/search header, two-row category rail, configurable StockFlow banner and product-first feed.
- Listing detail supports multiple photos/videos, seller trust context, listing ID/report action and a public **approximate 10 km area** map. Exact seller coordinates and private dispatch address are never included in the public listing response.
- `I’m interested` remains the default buyer action. Direct buyer/seller messaging stays locked unless the protected promise-fee entitlement exists.

## Seller experience

- New listings are submitted as `pending_review`; they are not public until an admin approves them.
- Listings support at most **8 media items**, including at most **2 videos**. Images are capped at 5 MB. Videos are capped at 10 MB and 30 seconds.
- Rejected listings show the moderator reason in My Stock. Sellers can edit title, description, category, price, quantity, MOQ and replace/remove media before resubmitting.
- Seller verification now includes optional legal name, GSTIN, PAN, Udyam, website, designation, operating years, warehouse count, monthly stock volume and primary categories.
- Stock address remains private and supports current-location reverse geocoding and map-assisted selection.

## Authentication correction

`Sign in` and `Create account` are separate backend intents. A phone number that does not exist receives a create-account instruction instead of silently creating a new user. Registration on an existing number sends the user back to sign in.

## Admin operations

The GitHub Pages admin console now includes:

- marketplace overview, charts and product performance;
- listing moderation with complete photo/video inspection;
- private full address + exact GPS inspection for operations only;
- approve/reject/remove listing actions with review history;
- seller verification with tax/business metadata;
- user account controls (active/suspended/banned);
- mediated deal desk and promise-fee visibility;
- orders, reports, diagnostics/security events and exact admin supply map.

Admin actions use a single delegated event handler and in-console reason dialogs so controls keep working after live table rerenders.

## Shared backend / future website

Android, iOS, the future StockFlow website and admin console are designed to use the same Supabase/Postgres source of truth and business APIs. Media, moderation, users, deals, orders and addresses are therefore not mobile-only data models.

## Defense in depth

- DB trigger forces new listings to moderation even if a modified client tries to submit `active`.
- DB media guard enforces item/video limits.
- public feed/detail use explicit safe column allow-lists;
- exact location is stored separately and only an approximate public area is returned;
- API rate limiting, request caps, security event logging, session checks and contact-exchange guards remain enabled;
- AI/service-role credentials are never embedded in Flutter/admin bundles.
