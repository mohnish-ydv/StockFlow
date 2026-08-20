# StockFlow v1.0.0 — Final UX audit

## Problem found

The earlier builds were feature-complete but presented the product like a generated prototype: a marketing landing page before marketplace value, repeated trust/feature blocks, card-heavy seller/account dashboards, too many visual containers, and authentication before the user could naturally evaluate inventory.

## Final product decision

StockFlow now behaves like a marketplace first and a marketing page never. Signed-out users open directly into Home, can browse/search/evaluate inventory, and are authenticated only when starting account-dependent actions.

## Research principles applied

- Delay authentication until it is exchanged for user value.
- Put search on the marketplace Home surface.
- Use feed layouts for browsing large collections of listings.
- Keep chat linked to the item/deal context.
- Separate buyer activity, seller posting and seller inventory management into distinct destinations.
- Use consistent component states, spacing and platform conventions.

## Visual changes

- Removed the runtime landing screen entirely.
- Removed floating/oversized Sell navigation treatment.
- Removed My Stock metric-card dashboard.
- Removed seller Sell-dashboard hero/status cards.
- Flattened Account into familiar marketplace rows and sections.
- Reduced listing cards to the information buyers use at scan time: image, price, title, MOQ/stock and location.
- Reduced listing detail to one clear commercial hierarchy and a maximum of three bottom actions.
- Removed staging/preview language from release UI.
- Staging OTP helper is debug-only.

## Navigation

Home / Chats / Sell / My stock / Account

## Auth gating

Public: Home, search, categories, listing detail, recently viewed, local save state, Help, Terms, Privacy.

Authenticated: Chat, Offer, Cart/Checkout, Sell, My stock, orders, seller management and account activity.

## Production provider handoff

The UX is intended to remain stable while production SMS/OTP, payment and logistics adapters are integrated.

## Final commerce-surface pass

The release candidate also removes generic segmented controls and repeated card containers from high-frequency transactional screens:

- Orders uses quiet Buying / Selling tabs and flat order rows.
- Order details uses document-like sections rather than stacked dashboard cards.
- Checkout uses plain payment rows with a single selected state and a flat order summary.
- Cart keeps quantity, subtotal and checkout hierarchy separate instead of turning every cart item into a large primary CTA.
- Sell inventory type and fulfilment choices use direct list rows instead of segmented/promo-card patterns.

These changes are intentionally conservative. Product images, price, quantity, seller context, status, actions and fulfilment information remain the visual anchors.
