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

  @override
  Set<Column> get primaryKey => {id};
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

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalTrips, LocalEvidence])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'tanktrail'));

  @override
  int get schemaVersion => 1;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
