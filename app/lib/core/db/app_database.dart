import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// On-phone copy of everything a driver records. Logs are saved here first and
/// (from Milestone 5) uploaded later, so nothing is lost while offline.
/// IDs are the future Firestore document IDs, generated on the phone.

/// One trip. Coordinates stay on the phone until they go to the admin-only
/// private/geo doc; they never go into the public trip doc.
class LocalTrips extends Table {
  TextColumn get id => text()();
  TextColumn get driverId => text()();
  TextColumn get driverName => text()();

  /// 'open' until the end reading and photo are saved, then 'closed'.
  TextColumn get status => text()();

  IntColumn get startOdo => integer()();
  DateTimeColumn get startedAt => dateTime()();
  RealColumn get startLat => real()();
  RealColumn get startLng => real()();
  RealColumn get startAcc => real()();
  BoolColumn get startMock => boolean()();

  IntColumn get endOdo => integer().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get endLat => real().nullable()();
  RealColumn get endLng => real().nullable()();
  RealColumn get endAcc => real().nullable()();
  BoolColumn get endMock => boolean().nullable()();

  /// Sync of the start / end part to Firestore (schema v3), see [SyncState].
  TextColumn get startSync => text().withDefault(const Constant(SyncState.local))();
  TextColumn get endSync => text().withDefault(const Constant(SyncState.local))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where a log (or part of one) is on its way to Firestore.
abstract final class SyncState {
  /// Only on this phone (files may still be uploading).
  static const local = 'local';

  /// Handed to Firestore's offline queue; delivered when online.
  static const sent = 'sent';

  /// Confirmed by the server.
  static const synced = 'synced';

  /// The server refused it (see syncError). Data stays on the phone.
  static const rejected = 'rejected';
}

/// Upload progress of one evidence file to Cloudinary.
abstract final class UploadState {
  static const pending = 'pending';
  static const uploading = 'uploading';
  static const uploaded = 'uploaded';
}

/// One photo or video, with where and when it was captured.
class LocalEvidence extends Table {
  TextColumn get id => text()();

  /// The trip or fuel log this belongs to.
  TextColumn get logId => text()();

  /// 'trip' or 'fuel'.
  TextColumn get logKind => text()();

  /// 'start' / 'end' for trips, 'fill' for fuel logs.
  TextColumn get phase => text()();

  /// 'odometer', 'pump' or 'video'.
  TextColumn get type => text()();

  /// Absolute path of the stored file (EXIF already stripped).
  TextColumn get filePath => text()();
  TextColumn get sha256 => text()();
  DateTimeColumn get capturedAtDevice => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get acc => real()();
  BoolColumn get mock => boolean()();
  IntColumn get durationSec => integer().nullable()();

  /// What on-device OCR read from the photo (raw text), for an admin-only
  /// soft hint. Null for videos or when OCR found nothing. (Added in schema v2.)
  TextColumn get ocrText => text().nullable()();

  /// Upload to Cloudinary (schema v3), see [UploadState].
  TextColumn get uploadState => text().withDefault(const Constant(UploadState.pending))();
  TextColumn get url => text().nullable()();
  TextColumn get publicId => text().nullable()();
  TextColumn get uploadError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One fuel fill. Fills are by amount (rupees), not full tank.
class LocalFuelLogs extends Table {
  TextColumn get id => text()();
  TextColumn get driverId => text()();
  TextColumn get driverName => text()();
  IntColumn get odometer => integer()();
  RealColumn get liters => real()();
  RealColumn get pricePerL => real()();
  RealColumn get total => real()();

  /// petrol | diesel | cng | other
  TextColumn get fuelType => text()();

  /// company_cash | own
  TextColumn get paidBy => text()();

  /// Phone clock when the driver saved the fill.
  DateTimeColumn get capturedAtDevice => dateTime()();

  /// Fill location = the GPS fix taken with the pump photo (at the pump).
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get acc => real()();
  BoolColumn get mock => boolean()();

  /// Mirrors the server status once synced; 'pending' until the admin reviews.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Sync to Firestore (schema v3), see [SyncState].
  TextColumn get sync => text().withDefault(const Constant(SyncState.local))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalTrips, LocalEvidence, LocalFuelLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'tanktrail'));

  // v1: trips + evidence (M3). v2: fuel logs + evidence.ocrText (M4).
  // v3: upload state per file, sync state per log (M5).
  @override
  int get schemaVersion => 3;

  // Upgrades keep existing rows: data on the phone is never dropped.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(localEvidence, localEvidence.ocrText);
            // Created with all current columns, so v3 below skips its own adds.
            await m.createTable(localFuelLogs);
          }
          if (from < 3) {
            for (final c in [localTrips.startSync, localTrips.endSync, localTrips.syncError]) {
              await m.addColumn(localTrips, c);
            }
            for (final c in [
              localEvidence.uploadState,
              localEvidence.url,
              localEvidence.publicId,
              localEvidence.uploadError,
            ]) {
              await m.addColumn(localEvidence, c);
            }
            if (from == 2) {
              await m.addColumn(localFuelLogs, localFuelLogs.sync);
              await m.addColumn(localFuelLogs, localFuelLogs.syncError);
            }
          }
        },
      );

  /// Highest odometer reading in any trip or fill on this phone. Derived on
  /// every read, never stored, so late or out-of-order logs can't corrupt it.
  Stream<int?> watchLastOdometer() {
    return customSelect(
      'SELECT MAX(v) AS last FROM ('
      ' SELECT start_odo AS v FROM local_trips'
      ' UNION ALL SELECT end_odo FROM local_trips'
      ' UNION ALL SELECT odometer FROM local_fuel_logs)',
      readsFrom: {localTrips, localFuelLogs},
    ).watchSingle().map((row) => row.read<int?>('last'));
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
