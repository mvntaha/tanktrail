import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/core/db/app_database.dart';
import 'package:tanktrail/core/sync/sync_service.dart';
import 'package:tanktrail/features/auth/domain/app_user.dart';
import 'package:tanktrail/features/evidence/data/evidence_uploader.dart';
import 'package:tanktrail/features/evidence/domain/captured_media.dart';
import 'package:tanktrail/features/fuel/data/fuel_repository.dart';
import 'package:tanktrail/features/trips/data/trip_repository.dart';

/// Records what would be uploaded; tests decide when uploads finish.
class FakeUploader implements EvidenceUploader {
  final enqueued = <PendingUpload>[];
  final active = <String>{};
  final _results = StreamController<UploadResult>.broadcast();
  bool offline = false;

  void finish(String mediaId) {
    active.remove(mediaId);
    _results.add(UploadResult.ok(mediaId, url: 'https://res.example/$mediaId', publicId: 'f/$mediaId'));
  }

  void fail(String mediaId) {
    active.remove(mediaId);
    _results.add(UploadResult.failed(mediaId, 'failed 500'));
  }

  @override
  Future<void> start() async {}
  @override
  Stream<UploadResult> get results => _results.stream;
  @override
  Future<bool> isActive(String mediaId) async => active.contains(mediaId);
  @override
  Future<void> enqueue(List<PendingUpload> items) async {
    if (offline) throw Exception('no internet');
    enqueued.addAll(items);
    active.addAll(items.map((i) => i.mediaId));
  }
}

const _ali = AppUser(
  uid: 'ali',
  name: 'Ali',
  email: 'ali@example.com',
  role: UserRole.driver,
  active: true,
  locationNoticeAccepted: true,
);

CapturedMedia _m(String id, String type, {String? ocr}) => CapturedMedia(
      id: id,
      type: type,
      filePath: '/data/app_flutter/evidence/x/$id.jpg',
      sha256: 'sha-$id',
      capturedAtDevice: DateTime(2026, 10, 1, 9, int.parse(id.substring(id.length - 1))),
      fix: GeoFix(lat: 24.86, lng: 67.0, accuracyM: 6, mock: false, at: DateTime(2026, 10, 1, 9)),
      durationSec: type == 'video' ? 40 : null,
      ocrText: ocr,
    );

Future<void> settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeFirebaseFirestore fs;
  late FakeUploader up;
  late SyncService sync;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fs = FakeFirebaseFirestore();
    up = FakeUploader();
    sync = SyncService(db: db, firestore: fs, currentUid: () => 'ali', uploader: up);
    await sync.start();
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  Future<String> uploadState(String id) async =>
      (await (db.select(db.localEvidence)..where((e) => e.id.equals(id))).getSingle()).uploadState;

  test('trip: start is written only after its photo is uploaded, then the end', () async {
    final trips = TripRepository(db);
    await trips.startTrip(tripId: 't1', driver: _ali, startOdo: 1000, photo: _m('p1', 'odometer', ocr: '1000'));
    await sync.kick();
    expect(up.enqueued.map((e) => e.mediaId), ['p1']);
    expect(await uploadState('p1'), UploadState.uploading);
    expect((await fs.doc('trips/t1').get()).exists, isFalse); // not before upload

    up.finish('p1');
    await settle();
    final trip = (await fs.doc('trips/t1').get()).data()!;
    // Exactly the keys the Firestore rules accept for a trip start.
    expect(trip.keys.toSet(),
        {'driverId', 'driverName', 'startOdo', 'startedAt', 'startEvidence', 'createdAt', 'status', 'edited'});
    expect(trip['status'], 'open');
    final item = (trip['startEvidence'] as List).single as Map;
    expect(item.keys.toSet(), {'type', 'url', 'publicId', 'sha256', 'capturedAtDevice'});
    final geo = (await fs.doc('trips/t1/private/geo').get()).data()!;
    expect(geo.keys.toSet(), {'startLoc', 'startEvidenceLocs'});
    expect((geo['startLoc'] as Map).keys.toSet(), {'lat', 'lng', 'acc', 'mock'});
    expect(((geo['startEvidenceLocs'] as List).single as Map)['ocrText'], '1000'); // OCR is admin-only
    expect((await db.select(db.localTrips).getSingle()).startSync, SyncState.synced);

    await trips.endTrip(tripId: 't1', endOdo: 1040, photo: _m('p2', 'odometer'));
    await sync.kick();
    expect((await fs.doc('trips/t1').get()).data()!['status'], 'open'); // end waits for its photo
    up.finish('p2');
    await settle();
    final closed = (await fs.doc('trips/t1').get()).data()!;
    expect(closed['status'], 'closed');
    expect(closed['endOdo'], 1040);
    expect((await fs.doc('trips/t1/private/geo').get()).data()!.containsKey('endLoc'), isTrue);
    expect((await db.select(db.localTrips).getSingle()).endSync, SyncState.synced);
  });

  test('fill: written once all 3 files are up, in a fixed order, no coordinates in public', () async {
    await FuelRepository(db).saveFill(
      id: 'f1',
      driver: _ali,
      odometer: 1200,
      liters: 15,
      pricePerL: 326.8,
      total: 4902,
      fuelType: 'petrol',
      paidBy: 'own',
      odometerPhoto: _m('o1', 'odometer'),
      pumpPhoto: _m('o3', 'pump'),
      pumpVideo: _m('o2', 'video'),
    );
    await sync.kick();
    expect(up.enqueued, hasLength(3));
    up.finish('o1');
    up.finish('o2');
    await settle();
    expect((await fs.doc('fuelLogs/f1').get()).exists, isFalse);

    up.finish('o3');
    await settle();
    final fill = (await fs.doc('fuelLogs/f1').get()).data()!;
    expect(fill.keys.toSet(), {
      'driverId', 'driverName', 'odometer', 'liters', 'pricePerL', 'total', 'fuelType', 'paidBy',
      'evidence', 'capturedAtDevice', 'createdAt', 'status', 'edited',
    });
    expect((fill['evidence'] as List).map((e) => (e as Map)['type']), ['odometer', 'pump', 'video']);
    expect(((fill['evidence'] as List).last as Map)['durationSec'], 40);
    expect(fill.toString().contains('24.86'), isFalse);
    final geo = (await fs.doc('fuelLogs/f1/private/geo').get()).data()!;
    expect(geo.keys.toSet(), {'loc', 'evidenceLocs'});
    expect((await db.select(db.localFuelLogs).getSingle()).sync, SyncState.synced);
  });

  test('offline: files stay pending and nothing is written', () async {
    up.offline = true;
    await TripRepository(db).startTrip(tripId: 't1', driver: _ali, startOdo: 5, photo: _m('p1', 'odometer'));
    await sync.kick();
    expect(await uploadState('p1'), UploadState.pending);
    expect(sync.lastError.value, 'Waiting for internet');

    up.offline = false; // internet is back
    await sync.kick();
    expect(await uploadState('p1'), UploadState.uploading);
  });

  test('a failed upload goes back to pending and is retried', () async {
    await TripRepository(db).startTrip(tripId: 't1', driver: _ali, startOdo: 5, photo: _m('p1', 'odometer'));
    await sync.kick();
    up.fail('p1');
    await settle();
    expect(await uploadState('p1'), UploadState.pending);
    await sync.kick();
    expect(up.enqueued.where((e) => e.mediaId == 'p1'), hasLength(2));
  });

  test('upload result without a response body derives the Cloudinary URL', () {
    final r = CloudinaryUploader.parseSuccess(
      'm1',
      '{"publicId":"tanktrail-dev/ali/L/m1","uploadUrl":"https://api.cloudinary.com/v1_1/demo/video/upload"}',
      null,
    );
    expect(r.url, 'https://res.cloudinary.com/demo/video/upload/tanktrail-dev/ali/L/m1');
    final withBody = CloudinaryUploader.parseSuccess(
      'm1',
      '{"publicId":"p","uploadUrl":"https://api.cloudinary.com/v1_1/demo/image/upload"}',
      '{"secure_url":"https://res.cloudinary.com/demo/image/upload/v1/p.jpg","public_id":"p"}',
    );
    expect(withBody.url, 'https://res.cloudinary.com/demo/image/upload/v1/p.jpg');
  });
}
