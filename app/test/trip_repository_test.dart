import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/core/db/app_database.dart';
import 'package:tanktrail/core/utils/format.dart';
import 'package:tanktrail/features/auth/domain/app_user.dart';
import 'package:tanktrail/features/evidence/domain/captured_media.dart';
import 'package:tanktrail/features/trips/data/trip_repository.dart';

const _ali = AppUser(
  uid: 'ali',
  name: 'Ali',
  email: 'ali@example.com',
  role: UserRole.driver,
  active: true,
  locationNoticeAccepted: true,
);

CapturedMedia _photo(String id) => CapturedMedia(
      id: id,
      type: 'odometer',
      filePath: '/tmp/$id.jpg',
      sha256: 'abc',
      capturedAtDevice: DateTime(2026, 10, 1, 9),
      fix: GeoFix(lat: 24.86, lng: 67.0, accuracyM: 8, mock: false, at: DateTime(2026, 10, 1, 9)),
    );

void main() {
  late AppDatabase db;
  late TripRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TripRepository(db);
  });
  tearDown(() => db.close());

  test('start then end a trip; evidence saved for both', () async {
    await repo.startTrip(tripId: 't1', driver: _ali, startOdo: 12000, photo: _photo('p1'));
    expect((await repo.watchOpen('ali').first)?.startOdo, 12000);

    await repo.endTrip(tripId: 't1', endOdo: 12042, photo: _photo('p2'));
    expect(await repo.watchOpen('ali').first, isNull);

    final trip = (await repo.watchRecent('ali').first).single;
    expect(trip.status, 'closed');
    expect(trip.distanceKm, 42);

    final evidence = await db.select(db.localEvidence).get();
    expect(evidence.map((e) => e.phase), containsAll(['start', 'end']));
    expect(evidence.every((e) => e.logId == 't1'), isTrue);
  });

  test('a closed trip cannot be ended again, and nothing is half-saved', () async {
    await repo.startTrip(tripId: 't1', driver: _ali, startOdo: 100, photo: _photo('p1'));
    await repo.endTrip(tripId: 't1', endOdo: 150, photo: _photo('p2'));
    await expectLater(repo.endTrip(tripId: 't1', endOdo: 160, photo: _photo('p3')), throwsStateError);
    // The transaction rolled back: no evidence row for p3.
    expect((await db.select(db.localEvidence).get()).map((e) => e.id), isNot(contains('p3')));
  });

  test('a lower end reading is saved (warn, never block)', () async {
    await repo.startTrip(tripId: 't1', driver: _ali, startOdo: 500, photo: _photo('p1'));
    await repo.endTrip(tripId: 't1', endOdo: 450, photo: _photo('p2'));
    expect((await repo.watchRecent('ali').first).single.distanceKm, -50);
  });

  test('last odometer is the highest reading of any trip', () async {
    expect(await repo.watchLastOdometer().first, isNull);
    await repo.startTrip(tripId: 't1', driver: _ali, startOdo: 1000, photo: _photo('p1'));
    await repo.endTrip(tripId: 't1', endOdo: 1080, photo: _photo('p2'));
    await repo.startTrip(tripId: 't2', driver: _ali, startOdo: 1075, photo: _photo('p3'));
    expect(await repo.watchLastOdometer().first, 1080);
  });

  test('format helpers', () {
    expect(formatKm(123456), '123,456 km');
    expect(formatThousands(-1234), '-1,234');
    final now = DateTime(2026, 10, 3, 18);
    expect(formatWhen(DateTime(2026, 10, 3, 9, 5), now: now), 'Today 09:05');
    expect(formatWhen(DateTime(2026, 10, 2, 23, 59), now: now), 'Yesterday 23:59');
    expect(formatWhen(DateTime(2026, 9, 28, 7, 0), now: now), '28 Sep 07:00');
  });
}
