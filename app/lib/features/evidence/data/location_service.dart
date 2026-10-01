import 'dart:async';

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
    return _toFix(p);
  }

  /// Live fixes, about one per second. Used ONLY while a capture screen is
  /// open, so a fix is ready the moment the driver taps the shutter.
  Stream<GeoFix> watch() => Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          intervalDuration: const Duration(seconds: 1),
        ),
      ).map(_toFix);

  static GeoFix _toFix(Position p) => GeoFix(
        lat: p.latitude,
        lng: p.longitude,
        accuracyM: p.accuracy,
        mock: p.isMocked,
        at: p.timestamp,
      );
}

/// Warms up GPS while a capture screen is open (the screen calls [stop] when
/// it closes). Not tracking: it runs only for the seconds the camera is shown,
/// and only the fix at the shutter moment is kept.
class GpsWarmup {
  GpsWarmup(this._service);

  final LocationService _service;
  StreamSubscription<GeoFix>? _sub;
  GeoFix? _latest;
  final _next = <Completer<GeoFix>>[];

  /// A fix this recent counts as "at the moment of capture".
  static const maxAge = Duration(seconds: 10);

  void start() {
    _sub ??= _service.watch().listen(
      (fix) {
        _latest = fix;
        for (final c in _next) {
          if (!c.isCompleted) c.complete(fix);
        }
        _next.clear();
      },
      onError: (Object _) {}, // a failed stream just means we wait for currentFix
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// The fix for a capture at [at]: the warm one if it's fresh, otherwise the
  /// next one from the stream, otherwise a one-shot request. Null on failure.
  Future<GeoFix?> fixFor(DateTime at) async {
    final latest = _latest;
    if (latest != null && at.difference(latest.at).abs() <= maxAge) return latest;
    try {
      if (_sub != null) {
        final c = Completer<GeoFix>();
        _next.add(c);
        return await c.future.timeout(const Duration(seconds: 45), onTimeout: _service.currentFix);
      }
      return await _service.currentFix();
    } catch (_) {
      return null; // no GPS signal; the screen offers "Try again"
    }
  }
}
