import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'constants.dart';

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude, required this.nearestCity});
  final double latitude;
  final double longitude;
  final CityRef nearestCity;
}

class LocationService {
  LocationService._();

  static Future<UserLocation?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final nearest = _findNearestCity(position.latitude, position.longitude);
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        nearestCity: nearest,
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }

  static CityRef _findNearestCity(double lat, double lng) {
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

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
