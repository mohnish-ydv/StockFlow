# StockFlow v0.3 — Marketplace UI Redesign Candidate

## Status
This is a CI candidate, not the final client release.

The entire Flutter presentation layer was redesigned after the previous interface was
rejected as prototype-like. Business logic from Part 1 and Part 2 is retained.

## Design direction
- Content-first resale marketplace rather than a dashboard/landing-page aesthetic.
- Neutral light content surfaces with a restrained deep-green identity.
- Android: minimal Material treatment with solid navigation/control surfaces.
- iOS: translucent glass is restricted to navigation/action/composer layers; product
  content remains solid and readable.
- Responsive grid and NavigationRail on wider layouts.
- Marketplace-native search, filters, sorting, listing hierarchy and seller flows.
- Random Picsum demo photos are never shown as product truth; absent/demo imagery uses
  category placeholders until the seller uploads a real product image.

## Screens rebuilt or materially restyled
- Authentication
- Home
- Search + filters + sorting
- Listing detail
- Cart
- Account / saved / recently viewed
- Chats
- Chat thread + structured offers
- Seller application
- Seller dashboard
- Create listing
- Checkout
- Offers
- Orders / tracking
- Adaptive bottom navigation / NavigationRail
- Splash / launch identity

## Branding
A temporary StockFlow staging launcher icon is included for Android and iOS. It is a
codename asset and can be replaced when the client chooses the final brand.

## CI gates
Android:
- platform generation
- INTERNET permission injection
- launcher branding
- secret leakage guard
- live staging API health
- design-regression guard
- flutter analyze --fatal-infos
- flutter test
- release APK build
- APK ZIP integrity
- final APK INTERNET permission inspection
- release artifact upload

iOS:
- platform generation
- iOS AppIcon replacement
- StockFlow display name
- secret + design-regression guard
- flutter analyze --fatal-infos
- flutter test
- unsigned release compile
- Runner.app sanity check
- artifact upload

## Required before calling this client-ready
1. Both Android and iOS CI jobs must be green.
2. Install the new Android release APK on a physical phone.
3. Visually inspect at minimum: Home, Search/Filters, Listing, Sell/Create Listing,
   Chat/Offer and Checkout.
4. Run buyer → seller → offer → checkout → order regression.
5. Fix any runtime or visual defect found, then rebuild.

Admin-panel hosting is intentionally tracked separately from this mobile UI redesign.
