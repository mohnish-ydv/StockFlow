# StockFlow v1.2.1 — dependency resolution fix

GitHub Actions failed before analysis/build because `geolocator 14.0.3` requires `package_info_plus ^10.0.0`, which requires `http ^1.6.0`, while v1.2.0 pinned `http 1.2.2`.

Changes:
- `http: ^1.6.0`
- version `1.2.1+19`
- Android/iOS artifact names bumped to v1.2.1
- CI preflight now guards the compatible `http` and `geolocator` constraints
- StockFlow app-version diagnostics bumped to 1.2.1

No client-requirement feature or UI flow was removed.
