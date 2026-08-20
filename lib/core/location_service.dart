import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum SfLocationIssue {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unavailable,
}

class SfLocationException implements Exception {
  final String message;
  final SfLocationIssue issue;

  const SfLocationException(this.message, this.issue);

  bool get canOpenSettings =>
      issue == SfLocationIssue.permissionDeniedForever ||
      issue == SfLocationIssue.serviceDisabled;

  @override
  String toString() => message;
}

class SfResolvedAddress {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String addressLine1;
  final String street;
  final String locality;
  final String district;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final String country;
  final bool addressResolved;

  const SfResolvedAddress({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.addressLine1,
    required this.street,
    required this.locality,
    required this.district,
    required this.city,
    required this.state,
    required this.pincode,
    required this.landmark,
    required this.country,
    required this.addressResolved,
  });

  String get compactLine1 => [addressLine1, street]
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .join(', ');
}

class SfLocationService {
  const SfLocationService._();

  /// Requests foreground permission in context so Android/iOS can show the
  /// runtime prompt exactly when the user taps "Use current location".
  static Future<Position> current() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const SfLocationException(
        'Location permission was not granted. You can still enter the address manually.',
        SfLocationIssue.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const SfLocationException(
        'Location permission is blocked for StockFlow. Open app settings and allow location while using the app.',
        SfLocationIssue.permissionDeniedForever,
      );
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const SfLocationException(
        'Device Location is turned off. Turn it on, then return to StockFlow.',
        SfLocationIssue.serviceDisabled,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const SfLocationException(
        'Could not lock your current location in time. Move near a window or enter the address manually.',
        SfLocationIssue.timeout,
      );
    } catch (_) {
      throw const SfLocationException(
        'Could not fetch your current location. Try again or enter the address manually.',
        SfLocationIssue.unavailable,
      );
    }
  }

  /// Resolves the current coordinates into native platform address components.
  /// Reverse-geocoding can legitimately return partial data, so callers always
  /// receive the coordinates and can let the user complete/edit the address.
  static Future<SfResolvedAddress> currentAddress() async {
    final position = await current();
    return resolveCoordinates(
      position.latitude,
      position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  static Future<SfResolvedAddress> resolveCoordinates(
    double latitude,
    double longitude, {
    double accuracyMeters = 0,
  }) async {
    Placemark? placemark;
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) placemark = placemarks.first;
    } catch (_) {
      // Map-picked coordinates remain useful even when reverse geocoding is
      // temporarily unavailable. The address form is intentionally editable.
    }

    String value(String? input) => (input ?? '').trim();
    String first(List<String?> values) {
      for (final item in values) {
        final cleaned = value(item);
        if (cleaned.isNotEmpty) return cleaned;
      }
      return '';
    }

    final street = first([
      placemark?.street,
      [value(placemark?.subThoroughfare), value(placemark?.thoroughfare)]
          .where((part) => part.isNotEmpty)
          .join(' '),
      placemark?.thoroughfare,
    ]);
    final locality = value(placemark?.subLocality);
    final city = first([placemark?.locality, placemark?.subAdministrativeArea]);
    final district = value(placemark?.subAdministrativeArea);
    final state = value(placemark?.administrativeArea);
    final pincode = value(placemark?.postalCode);
    final country = first([placemark?.country, 'India']);

    var addressLine1 = value(placemark?.name);
    final duplicates = {
      street.toLowerCase(),
      locality.toLowerCase(),
      city.toLowerCase(),
      district.toLowerCase(),
      state.toLowerCase(),
      pincode.toLowerCase(),
      country.toLowerCase(),
    }..remove('');
    if (duplicates.contains(addressLine1.toLowerCase())) addressLine1 = '';

    return SfResolvedAddress(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      addressLine1: addressLine1,
      street: street,
      locality: locality,
      district: district,
      city: city,
      state: state,
      pincode: pincode,
      landmark: '',
      country: country,
      addressResolved: placemark != null,
    );
  }

  static Future<bool> openSettingsFor(SfLocationIssue issue) {
    if (issue == SfLocationIssue.permissionDeniedForever) {
      return Geolocator.openAppSettings();
    }
    if (issue == SfLocationIssue.serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Future.value(false);
  }
}
