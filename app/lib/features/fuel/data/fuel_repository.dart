import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/session.dart';
import '../../evidence/data/evidence_dao.dart';
import '../../evidence/domain/captured_media.dart';
import '../domain/fuel_log.dart';

final fuelRepositoryProvider = Provider<FuelRepository>((ref) => FuelRepository(ref.watch(appDatabaseProvider)));

/// This driver's most recent fills saved on this phone.
final myFillsProvider = StreamProvider<List<FuelLog>>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session is! SignedIn) return Stream.value(const []);
  return ref.watch(fuelRepositoryProvider).watchRecent(session.user.uid);
});

class FuelRepository {
  FuelRepository(this._db);

  final AppDatabase _db;

  static FuelLog _toLog(LocalFuelLog r) => FuelLog(
        id: r.id,
        driverId: r.driverId,
        driverName: r.driverName,
        odometer: r.odometer,
        liters: r.liters,
        pricePerL: r.pricePerL,
        total: r.total,
        fuelType: r.fuelType,
        paidBy: r.paidBy,
        capturedAtDevice: r.capturedAtDevice,
        status: r.status,
      );

  Stream<List<FuelLog>> watchRecent(String driverId, {int limit = 20}) {
    final q = _db.select(_db.localFuelLogs)
      ..where((f) => f.driverId.equals(driverId))
      ..orderBy([(f) => OrderingTerm.desc(f.capturedAtDevice)])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(_toLog).toList());
  }

  /// Saves the fill and its three pieces of evidence together, or nothing.
  Future<void> saveFill({
    required String id,
    required AppUser driver,
    required int odometer,
    required double liters,
    required double pricePerL,
    required double total,
    required String fuelType,
    required String paidBy,
    required CapturedMedia odometerPhoto,
    required CapturedMedia pumpPhoto,
    required CapturedMedia pumpVideo,
  }) async {
    if (!fuelTypes.contains(fuelType)) throw ArgumentError.value(fuelType, 'fuelType');
    if (!paidByLabels.containsKey(paidBy)) throw ArgumentError.value(paidBy, 'paidBy');

    await _db.transaction(() async {
      await _db.into(_db.localFuelLogs).insert(LocalFuelLogsCompanion.insert(
            id: id,
            driverId: driver.uid,
            driverName: driver.name,
            odometer: odometer,
            liters: liters,
            pricePerL: pricePerL,
            total: total,
            fuelType: fuelType,
            paidBy: paidBy,
            capturedAtDevice: DateTime.now(),
            // The fill happened at the pump: use the pump photo's fix.
            lat: pumpPhoto.fix.lat,
            lng: pumpPhoto.fix.lng,
            acc: pumpPhoto.fix.accuracyM,
            mock: pumpPhoto.fix.mock,
          ));
      for (final m in [odometerPhoto, pumpPhoto, pumpVideo]) {
        await insertEvidence(_db, logId: id, logKind: 'fuel', phase: 'fill', media: m);
      }
    });
  }
}
