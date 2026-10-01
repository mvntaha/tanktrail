import 'dart:math';

import '../../evidence/domain/ocr_match.dart';
import 'admin_log.dart';

/// The owner's thresholds (chosen in Milestone 7; change here if needed).
class FlagSettings {
  const FlagSettings({
    this.maxDelay = const Duration(hours: 24),
    this.fuelTolerance = 0.15,
    this.gapKm = 1,
    this.priceToleranceRs = 1,
  });

  /// Flag when a log reached the server this long after capture.
  final Duration maxDelay;

  /// Flag when km until the next fill differs from litres x km/L by more than this.
  final double fuelTolerance;

  /// Ignore unlogged km up to this.
  final int gapKm;

  /// Flag when price per litre differs from the reference by more than this.
  final double priceToleranceRs;
}

enum FlagLevel { high, medium, low }

class Flag {
  const Flag(this.code, this.level, this.message);
  final String code;
  final FlagLevel level;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// One odometer reading from a trip start, trip end or fill.
class _Reading {
  _Reading(this.log, this.kind, this.odo, this.time);
  final AdminLog log;

  /// 'start' | 'end' | 'fill'
  final String kind;
  final int odo;
  final DateTime time;
}

String _km(int v) => '$v km';

/// Straight-line distance in km (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(a));
}

/// Computes flags for every log in the window. Never trusts drivers'
/// values: everything is derived here. Rejected fills are left out of the
/// reading-based checks, like they are left out of efficiency and cost.
/// Flags needing vehicle values (km/L, price, tank) stay off until set.
Map<String, List<Flag>> computeFlags(List<AdminLog> logs, Vehicle vehicle, {FlagSettings s = const FlagSettings()}) {
  final flags = <String, List<Flag>>{for (final l in logs) l.id: []};
  void add(AdminLog l, Flag f) => flags[l.id]!.add(f);

  final readings = <_Reading>[];
  for (final l in logs) {
    if (l.isRejected) continue;
    if (l.isTrip) {
      if (l.startOdo != null) readings.add(_Reading(l, 'start', l.startOdo!, l.deviceTime));
      if (l.endOdo != null) readings.add(_Reading(l, 'end', l.endOdo!, l.endedAt ?? l.deviceTime));
    } else if (l.odometer != null) {
      readings.add(_Reading(l, 'fill', l.odometer!, l.deviceTime));
    }
  }

  // 1. A reading lower than an earlier one (by phone time).
  final byTime = [...readings]..sort((a, b) => a.time.compareTo(b.time));
  _Reading? highest;
  for (final r in byTime) {
    if (highest != null && r.odo < highest.odo) {
      add(r.log, Flag('lower_than_earlier', FlagLevel.high,
          '${_km(r.odo)} is lower than ${_km(highest.odo)} recorded earlier by ${highest.log.driverName}.'));
    }
    if (highest == null || r.odo > highest.odo) highest = r;
  }

  // 2. Unlogged km: odometer ranges not covered by any closed trip.
  final intervals = [
    for (final l in logs)
      if (l.isTrip && l.startOdo != null && l.endOdo != null && l.endOdo! >= l.startOdo!) (l.startOdo!, l.endOdo!),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final iv in intervals) {
    if (merged.isNotEmpty && iv.$1 <= merged.last.$2) {
      merged.last = (merged.last.$1, max(merged.last.$2, iv.$2));
    } else {
      merged.add(iv);
    }
  }
  final byOdo = [...readings]..sort((a, b) => a.odo.compareTo(b.odo));
  if (byOdo.length >= 2) {
    var cursor = byOdo.first.odo;
    final gaps = <(int, int)>[];
    for (final iv in merged) {
      if (iv.$1 > cursor) gaps.add((cursor, iv.$1));
      cursor = max(cursor, iv.$2);
    }
    if (byOdo.last.odo > cursor) gaps.add((cursor, byOdo.last.odo));
    for (final g in gaps) {
      if (g.$2 - g.$1 <= s.gapKm) continue;
      // Shown on the first log at or after the end of the gap.
      final after = byOdo.firstWhere((r) => r.odo >= g.$2, orElse: () => byOdo.last);
      add(after.log, Flag('unlogged_km', FlagLevel.high,
          '${g.$2 - g.$1} km not covered by any trip (${_km(g.$1)} to ${_km(g.$2)}).'));
    }
  }

  // 3. Same reading recorded twice (two starts, two ends or two fills).
  final seen = <String, _Reading>{};
  for (final r in readings) {
    final key = '${r.kind}:${r.odo}';
    final other = seen[key];
    if (other != null && other.log.id != r.log.id) {
      add(r.log, Flag('duplicate', FlagLevel.medium, 'Same ${r.kind} reading ${_km(r.odo)} as another log by ${other.log.driverName}.'));
      add(other.log, Flag('duplicate', FlagLevel.medium, 'Same ${r.kind} reading ${_km(r.odo)} as another log by ${r.log.driverName}.'));
    } else {
      seen[key] = r;
    }
  }

  for (final l in logs) {
    // 4. Late arrival.
    final created = l.createdAt;
    if (created != null && created.difference(l.deviceTime) > s.maxDelay) {
      add(l, Flag('late', FlagLevel.medium,
          'Reached the server ${created.difference(l.deviceTime).inHours} h after it was recorded.'));
    }

    // 5. Mock location.
    final locs = [l.startLoc, l.endLoc, l.loc, ...l.privateMedia.map((p) => p.at)].whereType<GeoPoint2>();
    if (locs.any((g) => g.mock)) {
      add(l, const Flag('mock_location', FlagLevel.high, 'The phone reported a fake (mock) location.'));
    }

    // 6. OCR mismatch (soft: OCR often misreads these displays).
    for (final p in l.privateMedia) {
      if (p.type == 'odometer') {
        final typed = l.isTrip ? (p.phase == 'end' ? l.endOdo : l.startOdo) : l.odometer;
        if (typed != null && compareOcr(p.ocrText, typed, decimals: false) == OcrVerdict.mismatch) {
          add(l, Flag('ocr', FlagLevel.low, 'Odometer photo: OCR read "${_firstLine(p.ocrText)}", typed ${_km(typed)}.'));
        }
      } else if (p.type == 'pump' && !l.isTrip) {
        final values = [l.total, l.liters, l.pricePerL].whereType<double>();
        final verdicts = values.map((v) => compareOcr(p.ocrText, v, decimals: true)).toList();
        if (verdicts.isNotEmpty && verdicts.every((v) => v == OcrVerdict.mismatch)) {
          add(l, Flag('ocr', FlagLevel.low, 'Pump photo: OCR read "${_firstLine(p.ocrText)}", none of the typed amounts.'));
        }
      }
    }

    // 7. Odometer km less than the straight-line GPS distance.
    if (l.isTrip && l.startLoc != null && l.endLoc != null && l.startOdo != null && l.endOdo != null) {
      final a = l.startLoc!, b = l.endLoc!;
      final straight = distanceKm(a.lat, a.lng, b.lat, b.lng) - (a.acc + b.acc) / 1000;
      final odoKm = l.endOdo! - l.startOdo!;
      if (straight > odoKm + 0.5) {
        add(l, Flag('gps_vs_odometer', FlagLevel.high,
            'Start and end are ${straight.toStringAsFixed(1)} km apart in a straight line, but the odometer shows $odoKm km.'));
      }
    }

    // 8. Edited after submission (the detail screen shows the diff).
    if (l.edited) add(l, const Flag('edited', FlagLevel.low, 'Edited by the driver after it was sent.'));

    if (!l.isTrip) {
      // 9. Price per litre vs reference (only if set).
      final ref = vehicle.referencePricePerL;
      if (ref != null && l.pricePerL != null && (l.pricePerL! - ref).abs() > s.priceToleranceRs) {
        add(l, Flag('price', FlagLevel.medium,
            'Rs ${l.pricePerL!.toStringAsFixed(2)}/L differs from the reference Rs ${ref.toStringAsFixed(2)}/L.'));
      }
      // More than the tank holds (only if set).
      final tank = vehicle.tankCapacityL;
      if (tank != null && l.liters != null && l.liters! > tank) {
        add(l, Flag('over_tank', FlagLevel.high,
            '${l.liters!.toStringAsFixed(2)} L is more than the ${tank.toStringAsFixed(0)} L tank holds.'));
      }
    }
  }

  // 10. Km driven until the next fill vs litres x km/L (only if km/L is set).
  final kmPerL = vehicle.baselineKmPerL;
  if (kmPerL != null && kmPerL > 0) {
    final fills = [
      for (final l in logs)
        if (!l.isTrip && !l.isRejected && l.odometer != null && l.liters != null) l,
    ]..sort((a, b) => a.odometer!.compareTo(b.odometer!));
    for (var i = 0; i + 1 < fills.length; i++) {
      final f = fills[i];
      final actual = fills[i + 1].odometer! - f.odometer!;
      final expected = f.liters! * kmPerL;
      if (expected > 0 && (actual - expected).abs() / expected > s.fuelTolerance) {
        add(f, Flag('fuel_vs_km', FlagLevel.medium,
            '${f.liters!.toStringAsFixed(2)} L should last about ${expected.round()} km, '
            'but the next fill came after $actual km.'));
      }
    }
  }

  return flags;
}

String _firstLine(String? text) => (text ?? '').split('\n').first.trim();

/// Window totals. Rejected fills are excluded; pending ones are included and counted.
class WindowStats {
  const WindowStats({this.km, required this.liters, required this.cost, required this.pendingFills, required this.fills});
  final int? km;
  final double liters;
  final double cost;
  final int pendingFills;
  final int fills;

  double? get kmPerL => km != null && liters > 0 ? km! / liters : null;
  double? get costPerKm => km != null && km! > 0 ? cost / km! : null;
}

WindowStats computeStats(List<AdminLog> logs) {
  final odos = <int>[
    for (final l in logs)
      if (!l.isRejected) ...[?l.startOdo, ?l.endOdo, ?l.odometer],
  ];
  final fills = logs.where((l) => !l.isTrip && !l.isRejected).toList();
  odos.sort();
  return WindowStats(
    km: odos.length >= 2 ? odos.last - odos.first : null,
    liters: fills.fold(0, (s, f) => s + (f.liters ?? 0)),
    cost: fills.fold(0, (s, f) => s + (f.total ?? 0)),
    pendingFills: fills.where((f) => f.isPending).length,
    fills: fills.length,
  );
}

/// Name of the named place this point falls in (closest wins), admin view only.
String? placeName(GeoPoint2? at, List<Place> places) {
  if (at == null) return null;
  Place? best;
  var bestM = double.infinity;
  for (final p in places) {
    final m = distanceKm(at.lat, at.lng, p.lat, p.lng) * 1000;
    if (m <= p.radiusM && m < bestM) {
      best = p;
      bestM = m;
    }
  }
  return best?.name;
}
