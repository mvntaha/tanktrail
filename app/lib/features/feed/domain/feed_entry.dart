import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/db/app_database.dart';

/// One photo or video in the feed: on Cloudinary ([url]) or, while still
/// sending, on this phone ([localPath]).
class FeedMedia {
  const FeedMedia({required this.type, this.url, this.localPath, this.durationSec});

  /// 'odometer' | 'pump' | 'video'
  final String type;
  final String? url;
  final String? localPath;
  final int? durationSec;

  bool get isVideo => type == 'video';

  /// Small Cloudinary preview (a still frame for videos), cached on the phone.
  String? get thumbUrl {
    final u = url;
    if (u == null) return null;
    const t = 'c_fill,w_240,h_240,q_auto';
    if (isVideo) {
      final i = u.lastIndexOf('.');
      final base = i > u.lastIndexOf('/') ? u.substring(0, i) : u;
      return '${base.replaceFirst('/video/upload/', '/video/upload/so_0,$t/')}.jpg';
    }
    return u.replaceFirst('/image/upload/', '/image/upload/$t,f_auto/');
  }

  static FeedMedia fromItem(Map<String, dynamic> m) => FeedMedia(
        type: m['type'] as String? ?? 'odometer',
        url: m['url'] as String?,
        durationSec: (m['durationSec'] as num?)?.toInt(),
      );

  static FeedMedia fromLocal(LocalEvidenceData e) =>
      FeedMedia(type: e.type, url: e.url, localPath: e.filePath, durationSec: e.durationSec);
}

enum FeedKind { trip, fill }

/// One trip or fuel fill as shown in the shared feed. Never contains a location.
class FeedEntry {
  const FeedEntry({
    required this.id,
    required this.kind,
    required this.driverId,
    required this.driverName,
    required this.time,
    required this.media,
    this.sending = false,
    this.edited = false,
    this.startOdo,
    this.endOdo,
    this.tripOpen = false,
    this.reviewed = false,
    this.odometer,
    this.liters,
    this.pricePerL,
    this.total,
    this.fuelType,
    this.paidBy,
    this.status,
    this.reviewNote,
    this.serverData,
  });

  final String id;
  final FeedKind kind;
  final String driverId;
  final String driverName;

  /// Server time when known, otherwise the phone's capture time.
  final DateTime time;
  final List<FeedMedia> media;

  /// Not confirmed by the server yet ("sending...").
  final bool sending;
  final bool edited;

  // Trip
  final int? startOdo;
  final int? endOdo;
  final bool tripOpen;
  final bool reviewed;

  // Fill
  final int? odometer;
  final double? liters;
  final double? pricePerL;
  final double? total;
  final String? fuelType;
  final String? paidBy;

  /// pending | approved | rejected (fills)
  final String? status;
  final String? reviewNote;

  /// The document as the server (or the offline cache) has it, if it exists
  /// there. Edits must quote these values as "previous" (the rules check it).
  final Map<String, dynamic>? serverData;

  bool get isTrip => kind == FeedKind.trip;
  int? get distanceKm => (startOdo != null && endOdo != null) ? endOdo! - startOdo! : null;

  /// Drivers may fix typed values until the admin approves/reviews.
  bool get editable => isTrip ? !reviewed : (status ?? 'pending') == 'pending';

  static DateTime _time(Map<String, dynamic> d, String deviceField) =>
      (d['createdAt'] as Timestamp?)?.toDate() ?? (d[deviceField] as Timestamp?)?.toDate() ?? DateTime.now();

  static List<FeedMedia> _items(Object? list) =>
      [for (final m in (list as List?) ?? const []) FeedMedia.fromItem((m as Map).cast<String, dynamic>())];

  factory FeedEntry.fromTripDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FeedEntry(
      id: doc.id,
      kind: FeedKind.trip,
      driverId: d['driverId'] as String? ?? '',
      driverName: d['driverName'] as String? ?? '',
      time: _time(d, 'startedAt'),
      media: [..._items(d['startEvidence']), ..._items(d['endEvidence'])],
      sending: doc.metadata.hasPendingWrites,
      edited: d['edited'] == true,
      startOdo: (d['startOdo'] as num?)?.toInt(),
      endOdo: (d['endOdo'] as num?)?.toInt(),
      tripOpen: d['status'] == 'open',
      reviewed: d['reviewed'] == true,
      serverData: d,
    );
  }

  factory FeedEntry.fromFillDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FeedEntry(
      id: doc.id,
      kind: FeedKind.fill,
      driverId: d['driverId'] as String? ?? '',
      driverName: d['driverName'] as String? ?? '',
      time: _time(d, 'capturedAtDevice'),
      media: _items(d['evidence']),
      sending: doc.metadata.hasPendingWrites,
      edited: d['edited'] == true,
      odometer: (d['odometer'] as num?)?.toInt(),
      liters: (d['liters'] as num?)?.toDouble(),
      pricePerL: (d['pricePerL'] as num?)?.toDouble(),
      total: (d['total'] as num?)?.toDouble(),
      fuelType: d['fuelType'] as String?,
      paidBy: d['paidBy'] as String?,
      status: d['status'] as String?,
      reviewNote: d['reviewNote'] as String?,
      serverData: d,
    );
  }

  /// This driver's trip as the phone has it (newer than the server while sending).
  factory FeedEntry.fromLocalTrip(LocalTrip t, List<LocalEvidenceData> ev, {FeedEntry? server}) => FeedEntry(
        id: t.id,
        kind: FeedKind.trip,
        driverId: t.driverId,
        driverName: t.driverName,
        time: server?.time ?? t.startedAt,
        media: ev.map(FeedMedia.fromLocal).toList(),
        sending: true,
        edited: server?.edited ?? false,
        startOdo: t.startOdo,
        endOdo: t.endOdo,
        tripOpen: t.status == 'open',
        reviewed: server?.reviewed ?? false,
        serverData: server?.serverData,
      );

  factory FeedEntry.fromLocalFill(LocalFuelLog f, List<LocalEvidenceData> ev, {FeedEntry? server}) => FeedEntry(
        id: f.id,
        kind: FeedKind.fill,
        driverId: f.driverId,
        driverName: f.driverName,
        time: server?.time ?? f.capturedAtDevice,
        media: ev.map(FeedMedia.fromLocal).toList(),
        sending: true,
        edited: server?.edited ?? false,
        odometer: f.odometer,
        liters: f.liters,
        pricePerL: f.pricePerL,
        total: f.total,
        fuelType: f.fuelType,
        paidBy: f.paidBy,
        status: server?.status ?? 'pending',
        reviewNote: server?.reviewNote,
        serverData: server?.serverData,
      );
}
