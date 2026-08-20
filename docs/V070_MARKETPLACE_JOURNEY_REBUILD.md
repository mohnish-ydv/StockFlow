# StockFlow v0.7.0 — Marketplace Journey Rebuild

## Client feedback interpreted

The client did not ask for an OLX visual clone. The useful signal is the way a mature marketplace separates user intent across screens:

- discovery belongs on Home;
- search/location/category are discovery controls;
- buyer and seller conversations have different mental contexts;
- posting an item is a guided flow, not a mega-form;
- seller listings deserve their own management destination;
- account/settings/help/legal should not all compete on one surface.

The StockFlow redesign keeps the existing brand, B2B surplus-stock positioning and commerce model while rebuilding navigation and task boundaries.

## Reference journey patterns reviewed

Current OLX India public/help material was reviewed for journey structure only. The inspected flow consistently connects Home search/category discovery to listing detail, then Chat/Make Offer; seller inventory is managed under My Ads; account and help live separately. None of the OLX logo, colors, banner art, copy, icons, screen code or proprietary visual assets are included in StockFlow.

## New StockFlow information architecture

### Bottom navigation

- Home
- Chats
- Sell (central primary action)
- My stock
- Account

Search is no longer a permanent bottom-navigation destination. It opens from Home because search is part of discovery, not a separate long-lived product area.

### Home

- brand + current city/state
- full-width search entry
- horizontal category discovery
- recently viewed stock when available
- fresh stock grid
- cart action

Removed from Home: redundant campaign-like sections and repeated near/bulk/shipping rails that made the marketplace feel assembled rather than intentional.

### Chats

- Buying / Selling segmented contexts
- focused All / Offers / Orders filters
- listing thumbnail, counterparty, price and last-message context in each conversation row
- existing private listing-linked thread and offer logic retained

### Sell

Approved sellers now see a compact action hub instead of another inventory dashboard. Posting opens a five-step flow:

1. Category + inventory type
2. Photo + product basics
3. Price + quantity + MOQ
4. Pickup/shipping + location
5. Description + review + publish

The backend payload remains compatible with the existing StockFlow staging API.

### My stock

Dedicated seller listing management:

- active listing count
- total available units
- Active / Other segments
- listing rows with photo, quantity, MOQ, status and price
- direct Post action
- seller-orders shortcut

Non-approved sellers get a clear seller-application/status handoff instead of a broken empty screen.

### Account

Account is deliberately shorter. It contains marketplace activity and entry points; deeper content is routed out:

- Cart, Orders, Offers, Saved, Recently viewed
- My stock / Post stock / Seller orders
- Settings
- Help & safety
- Sign out

Settings owns language, legal and privacy. Help & safety owns safer-deal guidance.

## What was intentionally not copied

- OLX blue brand/color system
- OLX logos or artwork
- promotional banners
- exact bottom-nav styling
- exact category artwork
- screen copy
- monetization/package flows
- layouts at pixel level

StockFlow retains its own typography, green accent, off-white foundation, B2B vocabulary, seller verification, MOQ/bulk inventory model, structured offers, private chat, pickup/shipping and checkout flows.
