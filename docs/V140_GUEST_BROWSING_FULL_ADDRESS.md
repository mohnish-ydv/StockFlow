# StockFlow v1.4.0 — Guest Browsing + Full Address

Build: `1.4.0+25`

## Product goals

This release fixes two marketplace-friction problems:

1. Buyers should be able to inspect stock before creating an account.
2. A seller stock location must be operationally usable; city/state/pincode alone is not enough for pickup/dispatch.

## Guest marketplace contract

`stockflow-api-v3` handles `categories`, `feed` and `listing` without requiring an `x-stockflow-session` token.

These public reads use an explicit field allow-list rather than serializing whole database rows. Public marketplace responses may include:

- listing ID/title/description/category,
- price/quantity/MOQ/unit,
- condition/inventory type,
- fulfilment flags,
- product image,
- seller public display identity/status,
- city/state.

They intentionally exclude:

- seller phone,
- pincode,
- house/building/street/locality/landmark,
- exact latitude/longitude,
- internal payment/session/security fields.

Protected actions still require authentication.

## Full seller address model

Private seller stock addresses use `staging_listing_addresses`:

- `address_line1`
- `street`
- `locality`
- `district`
- `city`
- `state`
- `pincode`
- `landmark`
- `country`
- optional latitude/longitude/accuracy
- source (`manual` / `device`)

The coordinate map layer remains separate so map analytics never need public listing address exposure.

## Reverse geocoding UX

`SfLocationService.currentAddress()` performs:

1. foreground permission check,
2. runtime permission request when needed,
3. device Location-service check,
4. high-accuracy current-position capture,
5. native reverse geocoding,
6. normalized address-component mapping.

The UI auto-fills whatever the platform geocoder returns, including street, locality, district, city, state and postal code. House/shop/unit information is still editable and must be verified by the user because reverse geocoding can return partial or building-level data.

If reverse geocoding fails but GPS succeeds, the coordinates are retained and the user can finish the address manually.

## Checkout

Buyer checkout reuses the same current-location resolver to fill the saved delivery-address form. Delivery addresses remain user-editable before order placement.

## Future website

Do not create a second marketplace database for web. The web client should call the same business API and share the same channel-neutral Postgres records. The API controls public/member/admin projections so private operational fields remain server-side regardless of client platform.

## Security boundary

The private address table has RLS enabled and direct `anon`/`authenticated` table privileges revoked. Public guest API reads do not query it.
