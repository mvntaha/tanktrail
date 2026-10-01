import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/core/db/app_database.dart';
import 'package:tanktrail/features/auth/domain/app_user.dart';
import 'package:tanktrail/features/evidence/domain/captured_media.dart';
import 'package:tanktrail/features/fuel/data/fuel_repository.dart';
import 'package:tanktrail/features/fuel/domain/fuel_log.dart';

const _ali = AppUser(
  uid: 'ali',
  name: 'Ali',
  email: 'ali@example.com',
  role: UserRole.driver,
  active: true,
  locationNoticeAccepted: true,
);

CapturedMedia _media(String id, String type, {double lat = 24.86, String? ocr, int? sec}) => CapturedMedia(
      id: id,
      type: type,
      filePath: '/tmp/$id',
      sha256: 'hash-$id',
      capturedAtDevice: DateTime(2026, 10, 1, 9),
      fix: GeoFix(lat: lat, lng: 67.0, accuracyM: 6, mock: false, at: DateTime(2026, 10, 1, 9)),
      ocrText: ocr,
      durationSec: sec,
    );

Future<void> _saveFill(FuelRepository repo, {String id = 'f1', int odo = 113300, String paidBy = 'own'}) {
  return repo.saveFill(
    id: id,
    driver: _ali,
    odometer: odo,
    liters: 15,
    pricePerL: 326.8,
    total: 4902,
    fuelType: 'petrol',
    paidBy: paidBy,
    odometerPhoto: _media('$id-odo', 'odometer', ocr: '11330O'),
    pumpPhoto: _media('$id-pump', 'pump', lat: 24.9),
    pumpVideo: _media('$id-vid', 'video', sec: 42),
  );
}

void main() {
  group('FuelRepository', () {
    late AppDatabase db;
    late FuelRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = FuelRepository(db);
    });
    tearDown(() => db.close());

    test('saves the fill with its 3 evidence items; location from pump photo', () async {
      await _saveFill(repo);
      final fill = (await repo.watchRecent('ali').first).single;
      expect(fill.total, 4902);
      expect(fill.status, 'pending');

      final row = await db.select(db.localFuelLogs).getSingle();
      expect(row.lat, 24.9); // the pump photo's fix, not the odometer's

      final ev = await db.select(db.localEvidence).get();
      expect(ev.map((e) => e.type), unorderedEquals(['odometer', 'pump', 'video']));
      expect(ev.firstWhere((e) => e.type == 'video').durationSec, 42);
      expect(ev.firstWhere((e) => e.type == 'odometer').ocrText, '11330O');
    });

    test('invalid paidBy is rejected and nothing is saved', () async {
      await expectLater(_saveFill(repo, paidBy: 'friend'), throwsArgumentError);
      expect(await db.select(db.localFuelLogs).get(), isEmpty);
      expect(await db.select(db.localEvidence).get(), isEmpty);
    });

    test('last odometer covers trips and fills', () async {
      await _saveFill(repo, odo: 113300);
      expect(await db.watchLastOdometer().first, 113300);
    });
  });

  group('amount helpers', () {
    test('suggestTotal rounds to paisa', () {
      expect(suggestTotal(15, 326.8), 4902.0);
      expect(suggestTotal(10.37, 281.99), 2924.24);
    });
    test('amountsConsistent allows pump rounding, flags real gaps', () {
      expect(amountsConsistent(15, 326.8, 4902), isTrue);
      expect(amountsConsistent(15, 326.8, 4902.9), isTrue); // within Rs 1 / 0.5%
      expect(amountsConsistent(15, 326.8, 5200), isFalse);
    });
  });

  test('upgrading a v1 phone database keeps existing trips', () async {
    // The exact tables Milestone 3 created (schema v1).
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE local_trips (id TEXT NOT NULL PRIMARY KEY, driver_id TEXT NOT NULL,
          driver_name TEXT NOT NULL, status TEXT NOT NULL, start_odo INTEGER NOT NULL,
          started_at INTEGER NOT NULL, start_lat REAL NOT NULL, start_lng REAL NOT NULL,
          start_acc REAL NOT NULL, start_mock INTEGER NOT NULL, end_odo INTEGER NULL,
          ended_at INTEGER NULL, end_lat REAL NULL, end_lng REAL NULL, end_acc REAL NULL,
          end_mock INTEGER NULL);''');
      raw.execute('''
        CREATE TABLE local_evidence (id TEXT NOT NULL PRIMARY KEY, log_id TEXT NOT NULL,
          log_kind TEXT NOT NULL, phase TEXT NOT NULL, type TEXT NOT NULL, file_path TEXT NOT NULL,
          sha256 TEXT NOT NULL, captured_at_device INTEGER NOT NULL, lat REAL NOT NULL,
          lng REAL NOT NULL, acc REAL NOT NULL, mock INTEGER NOT NULL, duration_sec INTEGER NULL);''');
      raw.execute("INSERT INTO local_trips VALUES ('t1','ali','Ali','closed',100,1759300000,"
          "1,2,5,0,150,1759303600,1,2,5,0)");
      raw.execute("INSERT INTO local_evidence VALUES ('p1','t1','trip','start','odometer','/x','h',"
          '1759300000,1,2,5,0,NULL)');
      raw.execute('PRAGMA user_version = 1');
    }));
    addTearDown(db.close);

    final trips = await db.select(db.localTrips).get();
    expect(trips.single.endOdo, 150);
    final ev = await db.select(db.localEvidence).getSingle();
    expect(ev.ocrText, isNull); // new column, empty for old rows
    expect(await db.select(db.localFuelLogs).get(), isEmpty); // new table exists
    expect(await db.watchLastOdometer().first, 150);
    expect(await db.customSelect('PRAGMA user_version').map((r) => r.read<int>('user_version')).getSingle(), 3);
    // v3 columns exist with safe defaults for old rows.
    expect(trips.single.startSync, SyncState.local);
    expect(ev.uploadState, UploadState.pending);
  });

  test('upgrading a v2 phone database (the owner phone after M4) keeps trips and fills', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE local_trips (id TEXT NOT NULL PRIMARY KEY, driver_id TEXT NOT NULL,
          driver_name TEXT NOT NULL, status TEXT NOT NULL, start_odo INTEGER NOT NULL,
          started_at INTEGER NOT NULL, start_lat REAL NOT NULL, start_lng REAL NOT NULL,
          start_acc REAL NOT NULL, start_mock INTEGER NOT NULL, end_odo INTEGER NULL,
          ended_at INTEGER NULL, end_lat REAL NULL, end_lng REAL NULL, end_acc REAL NULL,
          end_mock INTEGER NULL);''');
      raw.execute('''
        CREATE TABLE local_evidence (id TEXT NOT NULL PRIMARY KEY, log_id TEXT NOT NULL,
          log_kind TEXT NOT NULL, phase TEXT NOT NULL, type TEXT NOT NULL, file_path TEXT NOT NULL,
          sha256 TEXT NOT NULL, captured_at_device INTEGER NOT NULL, lat REAL NOT NULL,
          lng REAL NOT NULL, acc REAL NOT NULL, mock INTEGER NOT NULL, duration_sec INTEGER NULL,
          ocr_text TEXT NULL);''');
      raw.execute('''
        CREATE TABLE local_fuel_logs (id TEXT NOT NULL PRIMARY KEY, driver_id TEXT NOT NULL,
          driver_name TEXT NOT NULL, odometer INTEGER NOT NULL, liters REAL NOT NULL,
          price_per_l REAL NOT NULL, total REAL NOT NULL, fuel_type TEXT NOT NULL, paid_by TEXT NOT NULL,
          captured_at_device INTEGER NOT NULL, lat REAL NOT NULL, lng REAL NOT NULL, acc REAL NOT NULL,
          mock INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending');''');
      raw.execute("INSERT INTO local_trips VALUES ('t1','ali','Ali','open',100,1759300000,1,2,5,0,"
          'NULL,NULL,NULL,NULL,NULL,NULL)');
      raw.execute("INSERT INTO local_fuel_logs VALUES ('f1','ali','Ali',120,15,326.8,4902,'petrol','own',"
          "1759300000,1,2,5,0,'pending')");
      raw.execute("INSERT INTO local_evidence VALUES ('v1','f1','fuel','fill','video','/x','h',"
          "1759300000,1,2,5,0,40,NULL)");
      raw.execute('PRAGMA user_version = 2');
    }));
    addTearDown(db.close);

    expect((await db.select(db.localTrips).getSingle()).startSync, SyncState.local);
    final fill = await db.select(db.localFuelLogs).getSingle();
    expect(fill.total, 4902);
    expect(fill.sync, SyncState.local);
    final ev = await db.select(db.localEvidence).getSingle();
    expect(ev.durationSec, 40);
    expect(ev.uploadState, UploadState.pending);
    expect(await db.watchLastOdometer().first, 120);
  });
}
