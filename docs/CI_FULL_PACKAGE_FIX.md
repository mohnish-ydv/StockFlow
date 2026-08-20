# v0.4.1 full-package CI repair

The previous `StockFlow-v0.4-CI-Image-Fix.zip` was a patch-only archive. It contained
only the workflow and a CI note, not the Flutter app, launcher assets, or iOS icon set.
When that archive was used as the repository contents, `flutter create` recreated a
blank shell and CI then failed while copying missing branding assets.

This package is standalone. It restores the complete v0.4 Flutter source and merges the
latest image-smoke checks into it.

Additional hardening:
- Android and iOS jobs now run a source-package preflight immediately after checkout.
- The preflight fails with an explicit `Incomplete StockFlow source package` message if
  core Dart files, tests, or branding assets are absent.
- Android launcher assets are included for mdpi through xxxhdpi.
- The full iOS `AppIcon.appiconset` is included.
- The product-image smoke test still checks 12 preview listings, seller diversity,
  rejects Picsum and legacy Unsplash download endpoints, retries transient failures,
  and reports the exact failing URL.

The GitHub Actions runner remains the authoritative environment for Flutter analyzer,
unit tests, Android release build, and unsigned iOS release compilation.
