# StockFlow Android release-network fix

The Flutter Android template only grants INTERNET in development manifests by default.
StockFlow CI creates platform shells during every build, so the release/main manifest
must be patched after `flutter create`.

The Android CI now:
1. adds `android.permission.INTERNET` to the generated main manifest,
2. verifies it before compilation,
3. builds the release APK,
4. inspects the final APK with `aapt dump permissions`,
5. fails CI if INTERNET is absent.

The Flutter API layer also maps socket/timeout/client connection failures to concise,
user-facing StockFlow messages instead of exposing raw exceptions.
