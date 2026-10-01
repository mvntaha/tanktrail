import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/captured_media.dart';

/// Why location can't be used right now.
enum LocationProblem { serviceOff, denied, deniedForever }

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

/// One-shot GPS readings at log moments only. There is no background or
/// continuous tracking anywhere in the app.
class LocationService {
  /// Null when ready; otherwise what the driver must fix. Asks for permission
  /// if it hasn't been decided yet.
  Future<LocationProblem?> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationProblem.serviceOff;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => LocationProblem.denied,
      LocationPermission.deniedForever => LocationProblem.deniedForever,
      _ => null,
    };
  }

  Future<void> openFix(LocationProblem problem) async {
    switch (problem) {
      case LocationProblem.serviceOff:
        await Geolocator.openLocationSettings();
      case LocationProblem.denied:
        await Geolocator.requestPermission();
      case LocationProblem.deniedForever:
        await Geolocator.openAppSettings();
    }
  }

  /// A fresh fix. GPS works without internet but can take a while outdoors
  /// after a cold start, hence the generous limit. Throws on timeout.
  Future<GeoFix> currentFix() async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 45),
      ),
    );
    return GeoFix(
      lat: p.latitude,
      lng: p.longitude,
      accuracyM: p.accuracy,
      mock: p.isMocked,
      at: p.timestamp,
    );
  }
}
