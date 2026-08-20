# StockFlow v1.2.2 — analyzer + iOS SwiftPM CI fix

Target: `1.2.2+20`

CI failures repaired from `logs_87150021404.zip`:

1. `lib/core/api.dart` mixed optional positional and named parameters in `_extensionPost`.
   The helper now uses required positional `action` + `body`, followed by the named
   `bestEffort` flag.
2. `lib/core/diagnostics.dart` no longer imports unnecessary `dart:ui`.
3. Two `ApiException` constructions in `chat_thread_screen.dart` are `const`.
4. Flutter 3.47 generates an iOS Swift Package Manager shell by default, so a
   CocoaPods `ios/Podfile` is not guaranteed. The workflow now patches/geps the
   geolocator CocoaPods macro only when the Podfile exists, while retaining the
   `NSLocationWhenInUseUsageDescription` check for both dependency-manager paths.

No client-requested v1.2 features were removed.
