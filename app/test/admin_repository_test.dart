import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/features/admin/data/admin_repository.dart';
import 'package:tanktrail/features/admin/domain/admin_log.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late AdminRepository repo;
  final now = DateTime.now();

  setUp(() async {
    fs = FakeFirebaseFirestore();
    repo = AdminRepository(fs);
    await fs.doc('fuelLogs/f1').set({
      'driverId': 'ali',
      'driverName': 'Ali',
      'odometer': 1200,
      'liters': 15.0,
      'pricePerL': 326.8,
      'total': 4902.0,
      'fuelType': 'petrol',
      'paidBy': 'own',
      'evidence': [
        {'type': 'odometer', 'url': 'https://res.cloudinary.com/c/image/upload/v1/x/m1.jpg'},
      ],
      'capturedAtDevice': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'status': 'pending',
      'edited': false,
    });
    await fs.doc('fuelLogs/f1/private/geo').set({
      'loc': {'lat': 24.86, 'lng': 67.0, 'acc': 9.0, 'mock': false},
      'evidenceLocs': [
        {'mediaId': 'm1', 'type': 'odometer', 'lat': 24.86, 'lng': 67.0, 'acc': 9.0, 'mock': false, 'ocrText': '1200'},
      ],
    });
    // Outside a 7-day window.
    await fs.doc('fuelLogs/old').set({
      'driverId': 'ali',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 40))),
      'capturedAtDevice': Timestamp.fromDate(now.subtract(const Duration(days: 40))),
      'status': 'approved',
    });
  });

  test('loads the window with private geo and OCR', () async {
    final logs = await repo.logsSince(now.subtract(const Duration(days: 7)));
    expect(logs.map((l) => l.id), ['f1']);
    final f = logs.single;
    expect(f.loc!.acc, 9.0);
    expect(f.privateMedia.single.ocrText, '1200');
    expect(f.needsReview, isTrue);
  });

  test('approve / reject / reopen write only the fields the rules allow', () async {
    await repo.approveFill('f1');
    var d = (await fs.doc('fuelLogs/f1').get()).data()!;
    expect(d['status'], 'approved');
    expect(d['reviewedAt'], isNotNull);

    await expectLater(() => repo.rejectFill('f1', '   '), throwsArgumentError);
    await repo.rejectFill('f1', 'Pump photo unreadable');
    d = (await fs.doc('fuelLogs/f1').get()).data()!;
    expect([d['status'], d['reviewNote']], ['rejected', 'Pump photo unreadable']);

    await repo.reopenFill('f1');
    expect((await fs.doc('fuelLogs/f1').get()).data()!['status'], 'pending');
  });

  test('vehicle keeps blank optional values as null; places save', () async {
    await repo.saveVehicle(const Vehicle(name: 'Alto', plate: 'ABC-123', baselineKmPerL: 15));
    final v = await repo.vehicle();
    expect([v.name, v.baselineKmPerL, v.tankCapacityL, v.referencePricePerL], ['Alto', 15.0, null, null]);
    expect((await fs.doc('vehicle/main').get()).data()!.keys.toSet(),
        {'name', 'plate', 'fuelType', 'tankCapacityL', 'baselineKmPerL', 'referencePricePerL'});

    await repo.savePlace(const Place(id: '', name: 'Home', lat: 24.9, lng: 67.1));
    final places = await repo.places();
    expect(places.single.name, 'Home');
    expect(places.single.radiusM, 150);
  });

  test('trip review sets reviewed + server time, note optional', () async {
    await fs.doc('trips/t1').set({'driverId': 'ali', 'status': 'closed', 'startOdo': 1, 'endOdo': 2});
    await repo.setTripReviewed('t1', true, note: 'ok ');
    final d = (await fs.doc('trips/t1').get()).data()!;
    expect([d['reviewed'], d['adminNote']], [true, 'ok']);
    expect(d['reviewedAt'], isNotNull);
  });
}
