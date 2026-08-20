# StockFlow v0.3 — Marketplace UI research and design rationale

## Why the previous interface was rejected
The previous build looked like a generated productivity dashboard rather than a resale marketplace. The main problems were:
- dark + neon-lime visual treatment dominating product content,
- oversized rounded containers around almost every element,
- multiple badges competing for attention,
- marketing copy where shoppers expect inventory,
- decorative random demo imagery that did not match the listing,
- identical visual treatment across Android and iOS,
- “command center” language in ordinary shopping/selling flows.

## Research synthesis

### Marketplace pattern
Current OLX positioning emphasizes real product photos, selling price, location and owner/listing detail. Its help documentation also treats category, price, location, brand, condition and posted date as ordinary search filters, with relevance/recency/price sorting.

Carousell and Mercari similarly center listing creation, photo-led browsing, chat, offers/transactions and seller trust. The takeaway is not to clone any one product; it is to preserve the interaction grammar users already understand:
1. photo,
2. price,
3. concise title,
4. location / fulfilment,
5. seller trust,
6. chat / offer / buy.

### iOS
Apple's current Human Interface Guidelines describe Liquid Glass as a functional layer for controls and navigation, not a material to place throughout content cards. StockFlow therefore uses blur/translucency only on iOS navigation/action surfaces such as the bottom navigation, listing action bar, search control and checkout action bar. Product cards remain solid.

### Android
Current Android guidance recommends Material navigation bars for three-to-five top-level destinations on compact windows and navigation rails on larger windows. StockFlow keeps five stable destinations and switches to a rail at wider layouts.

## StockFlow design principles
1. **Inventory first** — product content appears before promotional copy.
2. **One visual hierarchy** — price > product title > location > inventory/condition.
3. **Restrained brand** — deep green is used for actions, selected states and trust, not as a neon background.
4. **Photos must be truthful** — demo random-photo URLs are replaced in the client by category placeholders. Seller uploads still render normally.
5. **Few badges** — only meaningful state such as bulk/featured appears on the image; shipping is a small secondary signal.
6. **Native-feeling platforms** — Android uses solid Material surfaces; iOS gets glass only where it functions as navigation/control chrome.
7. **Search is a marketplace tool** — location, condition, price, bulk, shipping, COD, negotiable filters plus price sorting.
8. **Seller tools can be denser** — metrics are appropriate inside the seller inventory area, but buyer browsing stays editorially quiet.
9. **No fake sophistication** — remove “radar”, “cockpit”, “command”, “unlock value” and similar generated-product language.
10. **Responsive by construction** — two-column phone grids, more columns on width, and navigation rail on expanded layouts.
11. **No framework branding** — generated Flutter launcher artwork is replaced by a temporary StockFlow codename icon on Android and iOS. It is intentionally easy to swap when the client supplies the final brand.

## Key implementation files
- `lib/core/theme.dart` — neutral light marketplace design system.
- `lib/core/platform_ui.dart` — platform route and iOS glass functional surfaces.
- `lib/widgets/product_image.dart` — real-image rendering and truthful staging placeholders.
- `lib/widgets/listing_card.dart` — compact photo-led marketplace card.
- `lib/screens/home_screen.dart` — inventory-first home.
- `lib/screens/search_screen.dart` — full marketplace filter/sort UX.
- `lib/screens/listing_detail_screen.dart` — product-first detail and platform-specific action layer.
- `lib/screens/home_shell.dart` — compact bottom navigation / expanded rail.
- `lib/screens/chat_thread_screen.dart` — subdued chat + iOS glass composer.
- `lib/screens/sell_screen.dart` — seller onboarding, inventory and create-listing redesign.
- `lib/screens/checkout_screen.dart` — straightforward commerce checkout.

## Release requirement
The redesign is not accepted merely because source files look correct. GitHub CI must pass analyzer, tests, Android release build, APK permission/integrity checks and iOS unsigned release compile, followed by a real-device visual smoke test.
