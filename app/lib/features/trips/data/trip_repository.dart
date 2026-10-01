import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/session.dart';
import '../../evidence/domain/captured_media.dart';
import '../domain/trip.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) => TripRepository(ref.watch(appDatabaseProvider)));

String? _myUid(Ref ref) {
  final session = ref.watch(sessionProvider).value;
  return session is SignedIn ? session.user.uid : null;
}

/// This driver's most recent trips (saved on this phone).
final myTripsProvider = StreamProvider<List<Trip>>((ref) {
  final uid = _myUid(ref);
  if (uid == null) return Stream.value(const []);
  return ref.watch(tripRepositoryProvider).watchRecent(uid);
});

/// This driver's open trip, if any. A driver has at most one at a time.
final myOpenTripProvider = StreamProvider<Trip?>((ref) {
  final uid = _myUid(ref);
  if (uid == null) return Stream.value(null);
  return ref.watch(tripRepositoryProvider).watchOpen(uid);
});

/// Highest odometer reading recorded on this phone, used only for a soft hint.
/// (Never stored: always derived, so late or out-of-order logs can't corrupt it.)
final lastOdometerProvider = StreamProvider<int?>((ref) => ref.watch(tripRepositoryProvider).watchLastOdometer());

/// A trip by ID, for the end-trip screen.
final tripByIdProvider = StreamProvider.family<Trip?, String>(
  (ref, id) => ref.watch(tripRepositoryProvider).watchById(id),
);

class TripRepository {
  TripRepository(this._db);

  final AppDatabase _db;

  static Trip _toTrip(LocalTrip r) => Trip(
        id: r.id,
        driverId: r.driverId,
        driverName: r.driverName,
        status: r.status,
        startOdo: r.startOdo,
        startedAt: r.startedAt,
        endOdo: r.endOdo,
        endedAt: r.endedAt,
      );

  Stream<List<Trip>> watchRecent(String driverId, {int limit = 20}) {
    final q = _db.select(_db.localTrips)
      ..where((t) => t.driverId.equals(driverId))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(_toTrip).toList());
  }

  Stream<Trip?> watchOpen(String driverId) {
    final q = _db.select(_db.localTrips)
      ..where((t) => t.driverId.equals(driverId) & t.status.equals('open'))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    return q.watchSingleOrNull().map((r) => r == null ? null : _toTrip(r));
  }

  Stream<Trip?> watchById(String id) {
    final q = _db.select(_db.localTrips)..where((t) => t.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _toTrip(r));
  }

  Stream<int?> watchLastOdometer() {
    final maxStart = _db.localTrips.startOdo.max();
    final maxEnd = _db.localTrips.endOdo.max();
    final q = _db.selectOnly(_db.localTrips)..addColumns([maxStart, maxEnd]);
    return q.watchSingle().map((row) {
      final a = row.read(maxStart);
      final b = row.read(maxEnd);
      if (a == null) return b;
      if (b == null) return a;
      return a > b ? a : b;
    });
  }

  /// Saves a new open trip and its start photo together.
  Future<void> startTrip({
    required String tripId,
    required AppUser driver,
    required int startOdo,
    required CapturedMedia photo,
  }) {
    return _db.transaction(() async {
      await _db.into(_db.localTrips).insert(LocalTripsCompanion.insert(
            id: tripId,
            driverId: driver.uid,
            driverName: driver.name,
            status: 'open',
            startOdo: startOdo,
            startedAt: DateTime.now(),
            // The trip's location is the fix taken with its odometer photo.
            startLat: photo.fix.lat,
            startLng: photo.fix.lng,
            startAcc: photo.fix.accuracyM,
            startMock: photo.fix.mock,
          ));
      await _insertEvidence(tripId, 'start', photo);
    });
  }

  /// Closes the trip with its end reading and photo, together.
  Future<void> endTrip({required String tripId, required int endOdo, required CapturedMedia photo}) {
    return _db.transaction(() async {
      final updated = await (_db.update(_db.localTrips)
            ..where((t) => t.id.equals(tripId) & t.status.equals('open')))
          .write(LocalTripsCompanion(
        status: const Value('closed'),
        endOdo: Value(endOdo),
        endedAt: Value(DateTime.now()),
        endLat: Value(photo.fix.lat),
        endLng: Value(photo.fix.lng),
        endAcc: Value(photo.fix.accuracyM),
        endMock: Value(photo.fix.mock),
      ));
      if (updated != 1) throw StateError('This trip is not open any more.');
      await _insertEvidence(tripId, 'end', photo);
    });
  }

  Future<void> _insertEvidence(String tripId, String phase, CapturedMedia m) {
    return _db.into(_db.localEvidence).insert(LocalEvidenceCompanion.insert(
          id: m.id,
          logId: tripId,
          logKind: 'trip',
          phase: phase,
          type: m.type,
          filePath: m.filePath,
          sha256: m.sha256,
          capturedAtDevice: m.capturedAtDevice,
          lat: m.fix.lat,
          lng: m.fix.lng,
          acc: m.fix.accuracyM,
          mock: m.fix.mock,
        ));
  }
}
