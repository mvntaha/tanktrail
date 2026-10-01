import 'package:cloud_firestore/cloud_firestore.dart';

import '../../feed/domain/feed_entry.dart';

/// A GPS reading as stored in private/geo (admin only).
class GeoPoint2 {
  const GeoPoint2({required this.lat, required this.lng, required this.acc, required this.mock});
  final double lat;
  final double lng;

  /// Accuracy radius in meters.
  final double acc;
  final bool mock;

  static GeoPoint2? from(Object? m) {
    if (m is! Map) return null;
    final lat = m['lat'], lng = m['lng'];
    if (lat is! num || lng is! num) return null;
    return GeoPoint2(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      acc: (m['acc'] as num?)?.toDouble() ?? 0,
      mock: m['mock'] == true,
    );
  }
}

/// Private per-file details: where it was taken and what OCR read.
class PrivateMedia {
  const PrivateMedia({required this.mediaId, required this.type, required this.phase, this.at, this.ocrText});
  final String mediaId;
  final String type;

  /// 'start' | 'end' for trips, 'fill' for fills.
  final String phase;
  final GeoPoint2? at;
  final String? ocrText;

  static List<PrivateMedia> list(Object? items, String phase) => [
        for (final m in (items as List?) ?? const [])
          if (m is Map)
            PrivateMedia(
              mediaId: m['mediaId'] as String? ?? '',
              type: m['type'] as String? ?? '',
              phase: phase,
              at: GeoPoint2.from(m),
              ocrText: m['ocrText'] as String?,
            ),
      ];
}

/// A trip or fill with everything the admin may see (incl. private/geo).
class AdminLog {
  const AdminLog({
    required this.id,
    required this.isTrip,
    required this.driverId,
    required this.driverName,
    required this.deviceTime,
    this.createdAt,
    this.media = const [],
    this.privateMedia = const [],
    this.edited = false,
    this.startOdo,
    this.endOdo,
    this.endedAt,
    this.tripOpen = false,
    this.reviewed = false,
    this.adminNote,
    this.startLoc,
    this.endLoc,
    this.odometer,
    this.liters,
    this.pricePerL,
    this.total,
    this.fuelType,
    this.paidBy,
    this.status,
    this.reviewNote,
    this.flagsReviewed = false,
    this.loc,
  });

  final String id;
  final bool isTrip;
  final String driverId;
  final String driverName;

  /// Phone clock at capture (trip start / fill save).
  final DateTime deviceTime;

  /// Server time it arrived (null while pending).
  final DateTime? createdAt;
  final List<FeedMedia> media;
  final List<PrivateMedia> privateMedia;
  final bool edited;

  // Trip
  final int? startOdo;
  final int? endOdo;
  final DateTime? endedAt;
  final bool tripOpen;
  final bool reviewed;
  final String? adminNote;
  final GeoPoint2? startLoc;
  final GeoPoint2? endLoc;

  // Fill
  final int? odometer;
  final double? liters;
  final double? pricePerL;
  final double? total;
  final String? fuelType;
  final String? paidBy;
  final String? status;
  final String? reviewNote;
  final bool flagsReviewed;
  final GeoPoint2? loc;

  bool get isRejected => !isTrip && status == 'rejected';
  bool get isPending => !isTrip && status == 'pending';

  /// Needs the admin: pending fills, unreviewed closed trips.
  bool get needsReview => isTrip ? (!reviewed && !tripOpen) : status == 'pending';

  /// The admin has dealt with any flags on it.
  bool get flagsHandled => isTrip ? reviewed : (flagsReviewed || status != 'pending');

  static DateTime? _t(Object? v) => (v as Timestamp?)?.toDate();

  factory AdminLog.fromTrip(String id, Map<String, dynamic> d, Map<String, dynamic>? geo) => AdminLog(
        id: id,
        isTrip: true,
        driverId: d['driverId'] as String? ?? '',
        driverName: d['driverName'] as String? ?? '',
        deviceTime: _t(d['startedAt']) ?? _t(d['createdAt']) ?? DateTime(2000),
        createdAt: _t(d['createdAt']),
        media: [
          for (final m in (d['startEvidence'] as List?) ?? const []) FeedMedia.fromItem((m as Map).cast()),
          for (final m in (d['endEvidence'] as List?) ?? const []) FeedMedia.fromItem((m as Map).cast()),
        ],
        privateMedia: [
          ...PrivateMedia.list(geo?['startEvidenceLocs'], 'start'),
          ...PrivateMedia.list(geo?['endEvidenceLocs'], 'end'),
        ],
        edited: d['edited'] == true,
        startOdo: (d['startOdo'] as num?)?.toInt(),
        endOdo: (d['endOdo'] as num?)?.toInt(),
        endedAt: _t(d['endedAt']),
        tripOpen: d['status'] == 'open',
        reviewed: d['reviewed'] == true,
        adminNote: d['adminNote'] as String?,
        startLoc: GeoPoint2.from(geo?['startLoc']),
        endLoc: GeoPoint2.from(geo?['endLoc']),
      );

  factory AdminLog.fromFill(String id, Map<String, dynamic> d, Map<String, dynamic>? geo) => AdminLog(
        id: id,
        isTrip: false,
        driverId: d['driverId'] as String? ?? '',
        driverName: d['driverName'] as String? ?? '',
        deviceTime: _t(d['capturedAtDevice']) ?? _t(d['createdAt']) ?? DateTime(2000),
        createdAt: _t(d['createdAt']),
        media: [for (final m in (d['evidence'] as List?) ?? const []) FeedMedia.fromItem((m as Map).cast())],
        privateMedia: PrivateMedia.list(geo?['evidenceLocs'], 'fill'),
        edited: d['edited'] == true,
        odometer: (d['odometer'] as num?)?.toInt(),
        liters: (d['liters'] as num?)?.toDouble(),
        pricePerL: (d['pricePerL'] as num?)?.toDouble(),
        total: (d['total'] as num?)?.toDouble(),
        fuelType: d['fuelType'] as String?,
        paidBy: d['paidBy'] as String?,
        status: d['status'] as String?,
        reviewNote: d['reviewNote'] as String?,
        flagsReviewed: d['flagsReviewed'] == true,
        loc: GeoPoint2.from(geo?['loc']),
      );
}

/// vehicle/main. Optional values start empty; flags that need them stay off.
class Vehicle {
  const Vehicle({
    this.name = '',
    this.plate = '',
    this.fuelType = 'petrol',
    this.tankCapacityL,
    this.baselineKmPerL,
    this.referencePricePerL,
  });

  final String name;
  final String plate;
  final String fuelType;
  final double? tankCapacityL;
  final double? baselineKmPerL;
  final double? referencePricePerL;

  bool get isSet => name.isNotEmpty;

  factory Vehicle.fromMap(Map<String, dynamic>? m) => m == null
      ? const Vehicle()
      : Vehicle(
          name: m['name'] as String? ?? '',
          plate: m['plate'] as String? ?? '',
          fuelType: m['fuelType'] as String? ?? 'petrol',
          tankCapacityL: (m['tankCapacityL'] as num?)?.toDouble(),
          baselineKmPerL: (m['baselineKmPerL'] as num?)?.toDouble(),
          referencePricePerL: (m['referencePricePerL'] as num?)?.toDouble(),
        );

  Map<String, dynamic> toMap() => {
        'name': name,
        'plate': plate,
        'fuelType': fuelType,
        'tankCapacityL': tankCapacityL,
        'baselineKmPerL': baselineKmPerL,
        'referencePricePerL': referencePricePerL,
      };
}

/// A named place (admin only). Logs within [radiusM] show its name.
class Place {
  const Place({required this.id, required this.name, required this.lat, required this.lng, this.radiusM = 150});
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusM;

  factory Place.fromMap(String id, Map<String, dynamic> m) => Place(
        id: id,
        name: m['name'] as String? ?? '',
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        radiusM: (m['radiusM'] as num?)?.toDouble() ?? 150,
      );

  Map<String, dynamic> toMap() => {'name': name, 'lat': lat, 'lng': lng, 'radiusM': radiusM};
}
