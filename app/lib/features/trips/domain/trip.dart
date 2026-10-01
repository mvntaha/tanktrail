/// A driver's trip as the app shows it. Coordinates are deliberately not part
/// of this model: drivers never see locations.
class Trip {
  const Trip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.startOdo,
    required this.startedAt,
    this.endOdo,
    this.endedAt,
  });

  final String id;
  final String driverId;
  final String driverName;

  /// 'open' or 'closed'.
  final String status;
  final int startOdo;
  final DateTime startedAt;
  final int? endOdo;
  final DateTime? endedAt;

  bool get isOpen => status == 'open';

  /// Km driven, once closed. Can be negative if a reading was mistyped; the
  /// app warns but never blocks (the admin flags it).
  int? get distanceKm => endOdo == null ? null : endOdo! - startOdo;
}
