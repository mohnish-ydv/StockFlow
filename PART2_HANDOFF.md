# StockFlow — Part 2 Handoff (M5–M9)

## Scope
Part 2 turns the Part 1 marketplace into a complete staging commerce loop while keeping real-money and courier providers swappable.

### M5 — Private chat
- Buyer/seller conversations are listing-linked.
- Phone numbers are never exposed in the marketplace chat UI/API.
- Messages refresh automatically while a thread is open and support pull/manual refresh elsewhere.

### M6 — Negotiation
- Structured quantity + unit-price offers.
- Counter, accept, reject and offer status tracking.
- Accepted buyer offers unlock checkout at the server-validated accepted price.

### M7 — Cart, address, checkout and orders
- Shipping-enabled listings can be added to cart.
- Saved delivery addresses.
- Buyer and seller order views.
- Server recalculates price and validates MOQ/stock; the Flutter client is never trusted for final totals.
- Atomic inventory decrement prevents two buyers from purchasing the same last stock.

### M8 — Payment adapter (staging)
- Prepaid mode is a zero-cost staging capture: **no real money is charged**.
- COD is shown only when the seller enabled both shipping and COD.
- Production payment gateway remains provider-agnostic and will be connected using client-owned credentials.

### M9 — Shipping/logistics adapter (staging)
- Mock/manual shipment with AWB.
- Seller progresses orders through processing, ready-to-ship, shipped, in-transit, out-for-delivery and delivered.
- Buyer sees shipment and status timeline.
- Production courier integration remains provider-agnostic.

## Admin Control Center
The admin API actions are present, but browser hosting is tracked separately from the mobile build. Hosted Supabase Edge Function/Storage HTML is not used as the final rendered admin frontend target; deploy the static admin UI to a normal web host before client handoff.

Admin staging credentials:
- Mobile: `9999999999`
- OTP: `246810`

Normal app staging OTP:
- Any 10-digit demo number
- OTP: `123456`

## Security
- No `sb_secret_...` credential is present in Flutter or the source package.
- Staging commerce tables are server-only (RLS enabled; anon/auth table privileges revoked).
- Checkout is executed through a server-only database function.
- `service_role` is explicitly granted checkout RPC execution while `anon` and `authenticated` are not.
- Supabase security advisor has no Part 2 WARN/ERROR findings; INFO notices on server-only tables are expected because they intentionally have no client RLS policies.
- Foreign-key indexes reported by the performance advisor were added. Remaining performance notices are fresh/unused-index INFO only.

## CI release gate
The workflow pins Flutter 3.47.0 and performs:
1. Generate Android/iOS shells.
2. Remove Flutter's generated default `test/widget_test.dart` (the exact Part 1 `MyApp` failure).
3. Resolve dependencies.
4. Scan Flutter source for privileged Supabase secret references.
5. Analyze.
6. Run unit tests.
7. Build release APK and verify it exists/non-empty.
8. Compile unsigned iOS release on macOS and verify `Runner.app` exists.
9. Upload both artifacts.

A source package is **not** considered a final client build until both GitHub Actions jobs are green.
