import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'constants.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.nearestCity,
  });
  final double latitude;
  final double longitude;
  final CityRef nearestCity;
}

enum LocationFailReason {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

class LocationResult {
  const LocationResult._({this.location, this.failReason});

  factory LocationResult.ok(UserLocation location) =>
      LocationResult._(location: location);

  factory LocationResult.fail(LocationFailReason reason) =>
      LocationResult._(failReason: reason);

  final UserLocation? location;
  final LocationFailReason? failReason;

  bool get isOk => location != null;
}

class LocationService {
  LocationService._();

  static Future<UserLocation?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await getCurrentLocationDetailed(timeout: timeout);
    return result.location;
  }

  static Future<LocationResult> getCurrentLocationDetailed({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.fail(LocationFailReason.servicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.fail(LocationFailReason.permissionDenied);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.fail(LocationFailReason.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      final nearest = nearestCity(position.latitude, position.longitude);
      return LocationResult.ok(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          nearestCity: nearest,
        ),
      );
    } on TimeoutException {
      return LocationResult.fail(LocationFailReason.timeout);
    } catch (e) {
      debugPrint('LocationService error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        return LocationResult.fail(LocationFailReason.timeout);
      }
      return LocationResult.fail(LocationFailReason.error);
    }
  }

  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static CityRef nearestCity(double lat, double lng) {
    CityRef best = supportedCities.first;
    double bestDist = double.infinity;
    for (final city in supportedCities) {
      final d = _haversineKm(lat, lng, city.latitude, city.longitude);
      if (d < bestDist) {
        bestDist = d;
        best = city;
      }
    }
    return best;
  }

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) =>
      _haversineKm(lat1, lon1, lat2, lon2);

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
