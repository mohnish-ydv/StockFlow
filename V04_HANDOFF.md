# StockFlow v0.4 — Human Marketplace + Motion Pass

## Status
CI candidate. Do not call this the final client release until Android + iOS CI is green and the Android APK passes a real-device visual/regression pass.

## What changed from v0.3
v0.3 removed the dark/neon prototype language, but real-device screenshots still felt too sparse and template-like. v0.4 fixes the product realism, information density and interaction layer rather than applying another cosmetic theme.

### Marketplace realism
- Live staging catalog expanded to 19 believable active listings across multiple Indian cities and sellers.
- Seed catalog no longer uses Picsum/random-image URLs.
- Home now has useful discovery rails: nearby stock, bulk lots, shippable stock and the full catalog.
- Product cards prioritise product photo, price/unit, stock, MOQ and location.
- Search keeps marketplace filters and sorting without turning results into a dashboard.
- Seller dashboard is flatter and more operational, with one inventory summary and a real stock list instead of a wall of metric cards.
- Staging conversations and orders are populated so chats/offers/tracking do not look like empty prototypes.

### Chat and negotiation
- Conversation rows include timestamps, listing context, seller verification and offer-aware previews.
- Thread header focuses on the person/business rather than repeating listing metadata.
- A compact listing context card stays inside the conversation.
- Offers are semantic conversational objects with pending/accepted/rejected/countered colour states and expiry context.
- Accepted offers keep the production checkout path.

### Motion system
Motion is semantic, not decorative.
- Seller review: custom animated hourglass with flowing sand and a physical 180° flip after the lower chamber fills.
- Order placed: parcel arrival + success check + lightweight confetti sequence.
- Product images: subtle load fade rather than per-image progress spinners.
- Product cards: short press-scale feedback.
- Home/search/chat/order list entry: restrained fade/slide for the first visible items.
- Favourite: animated heart state.
- Cart quantity: animated value change without full-screen reload flicker.
- Offer state: animated semantic status transitions.
- Listing photo selection: animated image reveal.
- Native Android/iOS route and navigation feedback remains intact.

All custom motion checks `MediaQuery.disableAnimations`; reduced-motion users receive static/instant equivalents.

## Platform treatment
### Android
- Solid Material surfaces.
- Material 3 NavigationBar with selected indicator.
- No blur/glass over product content.

### iOS
- Cupertino route transitions.
- Translucency is restricted to functional layers such as search, navigation and chat composer.
- Product and transaction content stays solid for legibility.

## Staging data prepared for client demo
The live staging project now contains:
- 19 active listings,
- multiple approved sellers across Delhi, Mumbai, Bengaluru, Jaipur and Surat,
- six buyer conversations for the existing demo buyer,
- structured pending/countered offers,
- multiple buyer orders including shipped and delivered examples,
- tracking history for seeded demo orders.

## Release gates
Android CI must pass:
1. platform generation,
2. INTERNET permission injection,
3. launcher branding,
4. secret-leak guard,
5. live staging API health,
6. preview-feed density/seller-diversity/photo smoke,
7. live loading check for the first preview product images,
8. v0.4 design/motion regression guard,
9. `flutter analyze --fatal-infos`,
10. Flutter tests (including reduced-motion widgets),
11. release APK build,
12. APK ZIP integrity,
13. final APK INTERNET permission inspection,
14. release artifact upload.

iOS CI must pass analyzer/tests and unsigned release compilation with the iOS icon/display name applied.

## Mandatory physical-device QA after CI
Inspect and exercise:
- Home with real photos and all discovery rails,
- Search/filter/sort,
- listing detail + favourite + cart,
- seller pending hourglass/status timeline,
- approved seller dashboard + create listing/photo picker,
- chat list + thread + offer/counter/accept,
- checkout + order-success animation,
- orders + tracking timeline,
- Android navigation and keyboard behaviour.

Only after that regression pass should v0.4 be shown as the next client build.
