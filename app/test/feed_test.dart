import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/core/db/app_database.dart';
import 'package:tanktrail/features/feed/data/feed_repository.dart';
import 'package:tanktrail/features/feed/domain/feed_entry.dart';

void main() {
  group('FeedMedia thumbnails', () {
    test('image gets a small cached transformation', () {
      const m = FeedMedia(type: 'pump', url: 'https://res.cloudinary.com/c/image/upload/v1/f/a/b.jpg');
      expect(m.thumbUrl, 'https://res.cloudinary.com/c/image/upload/c_fill,w_240,h_240,q_auto,f_auto/v1/f/a/b.jpg');
    });
    test('video gets a still frame as jpg', () {
      const m = FeedMedia(type: 'video', url: 'https://res.cloudinary.com/c/video/upload/v1/f/a/v.mp4');
      expect(m.thumbUrl, 'https://res.cloudinary.com/c/video/upload/so_0,c_fill,w_240,h_240,q_auto/v1/f/a/v.jpg');
    });
  });

  group('editing', () {
    late AppDatabase db;
    late FakeFirebaseFirestore fs;
    late FeedRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      fs = FakeFirebaseFirestore();
      repo = FeedRepository(fs, db);
    });
    tearDown(() => db.close());

    Future<void> localFill({required String sync}) => db.into(db.localFuelLogs).insert(LocalFuelLogsCompanion.insert(
          id: 'f1',
          driverId: 'ali',
          driverName: 'Ali',
          odometer: 1200,
          liters: 15,
          pricePerL: 326.8,
          total: 4902,
          fuelType: 'petrol',
          paidBy: 'own',
          capturedAtDevice: DateTime(2026, 10, 1),
          lat: 1,
          lng: 2,
          acc: 5,
          mock: false,
          sync: Value(sync),
        ));

    Future<void> serverFill({String status = 'pending'}) => fs.doc('fuelLogs/f1').set({
          'driverId': 'ali',
          'odometer': 1200,
          'liters': 15.0,
          'pricePerL': 326.8,
          'total': 4902.0,
          'fuelType': 'petrol',
          'paidBy': 'own',
          'status': status,
          'edited': false,
        });

    Future<EditOutcome> edit({double liters = 15.5, double total = 5065.4}) => repo.editFill(
          id: 'f1',
          uid: 'ali',
          odometer: 1200,
          liters: liters,
          pricePerL: 326.8,
          total: total,
          fuelType: 'petrol',
          paidBy: 'own',
        );

    test('submitted fill: changed fields + history with the exact previous values, one batch', () async {
      await localFill(sync: SyncState.synced);
      await serverFill();
      expect(await edit(), EditOutcome.sent);

      final doc = (await fs.doc('fuelLogs/f1').get()).data()!;
      expect(doc['liters'], 15.5);
      expect(doc['total'], 5065.4);
      expect(doc['edited'], isTrue);
      final editId = doc['lastEditId'] as String;
      final history = (await fs.doc('fuelLogs/f1/edits/$editId').get()).data()!;
      expect(history['editedBy'], 'ali');
      expect(history['previous'], {
        'odometer': 1200,
        'liters': 15.0,
        'pricePerL': 326.8,
        'total': 4902.0,
        'fuelType': 'petrol',
        'paidBy': 'own',
      });
      // The phone's copy follows the edit.
      expect((await db.select(db.localFuelLogs).getSingle()).liters, 15.5);
    });

    test('not yet submitted: changed on the phone only, no history', () async {
      await localFill(sync: SyncState.local);
      expect(await edit(), EditOutcome.savedOnPhone);
      expect((await fs.doc('fuelLogs/f1').get()).exists, isFalse);
      expect((await db.select(db.localFuelLogs).getSingle()).total, 5065.4);
    });

    test('approved fill is locked; unchanged values are a no-op', () async {
      await localFill(sync: SyncState.synced);
      await serverFill(status: 'approved');
      await expectLater(edit(), throwsStateError);

      await fs.doc('fuelLogs/f1').update({'status': 'pending'});
      expect(await edit(liters: 15, total: 4902), EditOutcome.noChanges);
      expect((await fs.doc('fuelLogs/f1').get()).data()!['edited'], isFalse);
    });

    test('trip: submitted start goes to the server, unsent end stays on the phone', () async {
      await db.into(db.localTrips).insert(LocalTripsCompanion.insert(
            id: 't1',
            driverId: 'ali',
            driverName: 'Ali',
            status: 'closed',
            startOdo: 1000,
            startedAt: DateTime(2026, 10, 1),
            startLat: 1,
            startLng: 2,
            startAcc: 5,
            startMock: false,
            endOdo: const Value(1040),
            startSync: const Value(SyncState.synced),
            endSync: const Value(SyncState.local), // end not sent yet
          ));
      await fs.doc('trips/t1').set({'driverId': 'ali', 'startOdo': 1000, 'status': 'open', 'edited': false});

      expect(await repo.editTrip(id: 't1', uid: 'ali', startOdo: 1001, endOdo: 1045), EditOutcome.sent);
      final doc = (await fs.doc('trips/t1').get()).data()!;
      expect(doc['startOdo'], 1001);
      expect(doc.containsKey('endOdo'), isFalse); // the end isn't on the server yet
      final history = (await fs.doc('trips/t1/edits/${doc['lastEditId']}').get()).data()!;
      expect(history['previous'], {'startOdo': 1000, 'endOdo': null});
      final local = await db.select(db.localTrips).getSingle();
      expect([local.startOdo, local.endOdo], [1001, 1045]); // sent later with the end
    });

    test('reviewed trip is locked', () async {
      await fs.doc('trips/t1').set({'driverId': 'ali', 'startOdo': 1000, 'status': 'open', 'reviewed': true});
      await expectLater(repo.editTrip(id: 't1', uid: 'ali', startOdo: 1001), throwsStateError);
    });
  });
}
