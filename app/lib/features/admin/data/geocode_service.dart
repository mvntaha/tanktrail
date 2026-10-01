import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final geocodeServiceProvider = Provider<GeocodeService>((ref) => GeocodeService());

/// Short address for a point, e.g. "Shahrah-e-Faisal, PECHS, Karachi".
/// Admin only, looked up only when a log's detail is opened.
final addressProvider = FutureProvider.family<String?, ({double lat, double lng})>(
  (ref, p) => ref.watch(geocodeServiceProvider).address(p.lat, p.lng),
);

/// Free reverse geocoding with OpenStreetMap's Nominatim, used per its policy
/// (operations.osmfoundation.org/policies/nominatim): only when the admin opens
/// a log (never in bulk or in the background), max 1 request per second, an
/// app-specific User-Agent, results cached on the phone forever, and
/// "© OpenStreetMap contributors" shown next to the address.
class GeocodeService {
  GeocodeService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  Map<String, String>? _cache;
  Future<void> _queue = Future.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// ~11 m grid: nearby points share one lookup.
  static String key(double lat, double lng) => '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/geocode_cache.json');

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      _cache = f.existsSync() ? (jsonDecode(await f.readAsString()) as Map).cast<String, String>() : {};
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  Future<String?> address(double lat, double lng) async {
    final cache = await _load();
    final k = key(lat, lng);
    if (cache.containsKey(k)) return cache[k];

    // One request at a time, at least 1.1 s apart.
    final done = Completer<String?>();
    _queue = _queue.then((_) async {
      final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _last = DateTime.now();
      try {
        final name = await _lookup(lat, lng);
        if (name != null) {
          cache[k] = name;
          await (await _file()).writeAsString(jsonEncode(cache));
        }
        done.complete(name);
      } catch (e) {
        debugPrint('Address lookup failed: $e'); // offline: just no name
        done.complete(null);
      }
    });
    return done.future;
  }

  Future<String?> _lookup(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '17',
      'accept-language': 'en',
    });
    final res = await _http
        .get(uri, headers: {'User-Agent': 'TankTrail/1.0 (com.tanktrail.app; admin review, low volume)'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    return shortAddress((jsonDecode(res.body) as Map).cast<String, dynamic>());
  }

  /// Picks a few readable parts instead of the very long display_name.
  @visibleForTesting
  static String? shortAddress(Map<String, dynamic> json) {
    final a = (json['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parts = <String>[];
    for (final group in [
      ['amenity', 'shop', 'building'],
      ['road'],
      ['neighbourhood', 'suburb', 'quarter'],
      ['city', 'town', 'village', 'county'],
    ]) {
      for (final k in group) {
        final v = a[k];
        if (v is String && v.isNotEmpty && !parts.contains(v)) {
          parts.add(v);
          break;
        }
      }
    }
    if (parts.isNotEmpty) return parts.join(', ');
    final display = json['display_name'] as String?;
    return display?.split(',').take(3).map((s) => s.trim()).join(', ');
  }
}
