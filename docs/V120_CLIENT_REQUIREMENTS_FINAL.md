# StockFlow v1.2.0 — Client requirements final pass

This release folds the client’s final operational requirements into the existing reference-quality StockFlow product language. The work is deliberately implemented as product infrastructure, not demo-only visual placeholders.

## 1. Seller location coordinates

- Posting stock includes an explicit **Use current location** action.
- Location permission is requested only after the seller taps that action.
- Android release shells request foreground coarse/fine location only; no background-location permission is requested.
- iOS release shells include a purpose-specific `NSLocationWhenInUseUsageDescription` and bypass the unused Always-location permission path.
- Exact latitude/longitude and accuracy are stored in `staging_listing_locations`, which has RLS enabled and no buyer-facing read policy.
- Buyer surfaces continue to expose only city/state. Exact coordinates are reserved for operations/admin analytics.

## 2. AI-assisted listing creation

The seller creation journey is now:

1. Add one real product/stock photo.
2. Enter a title and an optional one-line factual note.
3. Tap **Generate with AI**.
4. StockFlow drafts the longer buyer-facing description and chooses a category.
5. Seller reviews/edits the AI output, then continues to price, quantity, fulfilment/location and publish.

The AI key is never included in Flutter, GitHub Pages, CI, or repository source. Calls are proxied through the server-side `stockflow-extensions` Edge Function and the secret is read from a server-side secret store. AI output is constrained to the real StockFlow category slugs and prompted not to invent specifications, quantities, certifications, warranty, brand, model, material, packaging, or condition.

AI usage is rate-limited per seller and request success/failure is recorded for admin diagnostics.

## 3. Marketplace analytics

New private analytics data:

- listing events: view, chat, offer, cart, checkout
- seller approval timestamps
- listing GPS coordinates
- AI generation request outcomes
- client diagnostic/error references

Admin Overview now includes:

- listings: day / week / month / all time
- approved sellers: day / week / month / all time
- orders: day / week / month / all time
- marketplace order value
- 14-day listing/seller/order charts
- category distribution
- product performance: views, chats, offers, carts, orders, conversion and revenue
- private listing-location map plus area counts
- AI request volume and success rate
- customer-facing incident/error references for support tracing

Historical interaction analytics begin accumulating when clients using the v1.2 instrumentation interact with listings. Existing orders/listings remain available immediately; historical views/chats that were never recorded cannot be reconstructed retroactively.

## 4. Admin visual system

`docs/admin/index.html` is rebuilt with the same StockFlow cobalt/white visual system used in the mobile client. It remains a responsive GitHub Pages control centre and keeps seller approvals, listing moderation and order inspection while adding analytics, map and diagnostics views.

Exact GPS data is shown only in admin. The map uses OpenStreetMap tiles through Leaflet; product/location data still comes from StockFlow’s own backend.

## 5. Loading, error and support diagnostics

- Skeleton components are available for feed/list loading states.
- High-frequency Home/Search/Cart/Orders/My Stock/Offers/Account loading states use skeletons instead of generic full-page spinners.
- A branded in-app unknown-route screen and GitHub Pages `404.html` are included.
- API/network failures generate StockFlow incident IDs such as `SF-...` / backend trace references that can be shown to the customer and searched in admin diagnostics.
- Global Flutter and asynchronous error handlers feed best-effort diagnostics without making the original failure worse.
- Logs intentionally avoid request bodies, auth sessions, privileged keys, and AI secrets.

## 6. Advertising integration contract

Stable `SfAdSlot` hooks are included but the ad provider is disabled by default. This lets the production ad SDK/provider be connected without redesigning core screens or showing fake ad placeholders to the client before an actual provider is configured.

Current integration points include Home feed and listing detail. More slots should be introduced only after ad-format decisions are finalized to avoid degrading marketplace UX.

## 7. Backend changes already applied to staging

- `stockflow_client_final_features`
- `seller_approval_timestamps`
- `seller_approval_trigger_search_path_hardening`
- `client_feature_fk_index_hardening`
- `stockflow-extensions` Edge Function v2

The new private tables use RLS with no client-facing policies because all access is mediated by the server-side Edge Function/service-role path.

## 8. Release gate

The source package includes GitHub Actions guards for:

- AI-key leakage
- privileged Supabase credential leakage in Flutter/admin
- required location permissions and iOS purpose string
- extension health
- AI/location/diagnostics/ad/skeleton/404 feature presence
- Flutter analyzer + widget tests
- Android release APK
- unsigned iOS release compile

The local packaging environment does not include Flutter/Dart, so GitHub Actions remains the authoritative compile/test gate.

## Production key action

The Gemini credential supplied during development was provided in a chat message. Before public production traffic, create a fresh restricted/auth key, update the server-side secret, verify the AI action, and revoke the development credential. Never put the replacement key into Flutter, static admin HTML, GitHub Actions source, or repository files.
