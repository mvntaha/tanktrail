import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/features/admin/domain/admin_log.dart';
import 'package:tanktrail/features/admin/domain/flags.dart';

final _t0 = DateTime(2026, 10, 1, 8);

AdminLog trip(String id, int start, int? end,
        {int hour = 0, String driver = 'Ali', GeoPoint2? from, GeoPoint2? to, bool edited = false, DateTime? created, List<PrivateMedia> pm = const []}) =>
    AdminLog(
      id: id,
      isTrip: true,
      driverId: driver,
      driverName: driver,
      deviceTime: _t0.add(Duration(hours: hour)),
      endedAt: end == null ? null : _t0.add(Duration(hours: hour, minutes: 30)),
      createdAt: created ?? _t0.add(Duration(hours: hour, minutes: 1)),
      startOdo: start,
      endOdo: end,
      tripOpen: end == null,
      startLoc: from,
      endLoc: to,
      edited: edited,
      privateMedia: pm,
    );

AdminLog fill(String id, int odo,
        {int hour = 0, double liters = 10, double price = 280, double? total, String status = 'pending', List<PrivateMedia> pm = const [], GeoPoint2? loc}) =>
    AdminLog(
      id: id,
      isTrip: false,
      driverId: 'Ali',
      driverName: 'Ali',
      deviceTime: _t0.add(Duration(hours: hour)),
      createdAt: _t0.add(Duration(hours: hour, minutes: 1)),
      odometer: odo,
      liters: liters,
      pricePerL: price,
      total: total ?? liters * price,
      status: status,
      privateMedia: pm,
      loc: loc,
    );

const _here = GeoPoint2(lat: 24.8600, lng: 67.0000, acc: 10, mock: false);
List<String> codes(Map<String, List<Flag>> f, String id) => f[id]!.map((x) => x.code).toList();

void main() {
  test('clean consecutive trips with a fill mid-trip: no flags', () {
    final logs = [
      trip('t1', 1000, 1040, hour: 0),
      fill('f1', 1020, hour: 0), // during t1: covered by the trip, not a gap
      trip('t2', 1040, 1060, hour: 2), // starts where t1 ended: not a duplicate
    ];
    final f = computeFlags(logs, const Vehicle());
    expect(f.values.expand((x) => x), isEmpty);
  });

  test('lower than an earlier reading (by phone time)', () {
    final f = computeFlags([trip('t1', 1000, 1040, hour: 0), trip('t2', 990, 1000, hour: 3)], const Vehicle());
    expect(codes(f, 't2'), contains('lower_than_earlier'));
    expect(codes(f, 't1'), isNot(contains('lower_than_earlier')));
  });

  test('unlogged km gap above 1 km, ignoring 1 km', () {
    final f = computeFlags([trip('t1', 1000, 1040), trip('t2', 1041, 1050, hour: 2), trip('t3', 1065, 1070, hour: 4)],
        const Vehicle());
    expect(codes(f, 't2'), isNot(contains('unlogged_km'))); // 1 km: ignored
    expect(f['t3']!.single.message, contains('15 km'));
  });

  test('duplicate start readings', () {
    final f = computeFlags([trip('t1', 500, 510), trip('t2', 500, 505, hour: 1, driver: 'Bilal')], const Vehicle());
    expect(codes(f, 't1'), contains('duplicate'));
    expect(codes(f, 't2'), contains('duplicate'));
  });

  test('late arrival over 24 h', () {
    final f = computeFlags([trip('t1', 1, 2, created: _t0.add(const Duration(hours: 30)))], const Vehicle());
    expect(codes(f, 't1'), contains('late'));
  });

  test('mock location anywhere in the log', () {
    const fake = GeoPoint2(lat: 1, lng: 1, acc: 3, mock: true);
    expect(codes(computeFlags([fill('f1', 1, loc: fake)], const Vehicle()), 'f1'), contains('mock_location'));
  });

  test('OCR: mismatch flags softly, unreadable does not, near-miss letters match', () {
    final f = computeFlags([
      trip('t1', 113285, 113300, pm: const [
        PrivateMedia(mediaId: 'a', type: 'odometer', phase: 'start', ocrText: '11328S'), // matches
        PrivateMedia(mediaId: 'b', type: 'odometer', phase: 'end', ocrText: 'DL2E'), // unreadable
      ]),
      trip('t2', 200000, 200010, hour: 5, pm: const [
        PrivateMedia(mediaId: 'c', type: 'odometer', phase: 'start', ocrText: '199999'), // mismatch
      ]),
    ], const Vehicle());
    expect(codes(f, 't1'), isNot(contains('ocr')));
    expect(f['t2']!.where((x) => x.code == 'ocr').single.level, FlagLevel.low);
  });

  test('GPS straight line longer than odometer km', () {
    const far = GeoPoint2(lat: 24.9500, lng: 67.0000, acc: 10, mock: false); // ~10 km north
    final f = computeFlags([trip('t1', 1000, 1003, from: _here, to: far), trip('t2', 1003, 1015, hour: 1, from: _here, to: far)],
        const Vehicle());
    expect(codes(f, 't1'), contains('gps_vs_odometer'));
    expect(codes(f, 't2'), isNot(contains('gps_vs_odometer')));
  });

  test('edited flag', () {
    expect(codes(computeFlags([trip('t1', 1, 2, edited: true)], const Vehicle()), 't1'), ['edited']);
  });

  test('vehicle-dependent flags are off until set', () {
    final logs = [
      fill('f1', 1000, liters: 60, price: 300),
      trip('t1', 1000, 1100, hour: 1), // the km between the fills were driven on a trip
      fill('f2', 1100, hour: 5, liters: 10),
    ];
    expect(computeFlags(logs, const Vehicle()).values.expand((x) => x), isEmpty);

    final set = computeFlags(
      logs,
      const Vehicle(name: 'Alto', tankCapacityL: 35, baselineKmPerL: 15, referencePricePerL: 280),
    );
    expect(codes(set, 'f1'), containsAll(['price', 'over_tank', 'fuel_vs_km'])); // 60 L ≈ 900 km, came after 100
    expect(codes(set, 'f2'), isEmpty); // Rs 280 exact; last fill has no "next"
  });

  test('price within Rs 1 is fine', () {
    final f = computeFlags([fill('f1', 1, price: 280.9)], const Vehicle(name: 'Alto', referencePricePerL: 280));
    expect(codes(f, 'f1'), isEmpty);
  });

  test('rejected fills are ignored by reading checks and stats', () {
    final logs = [trip('t1', 1000, 1100), fill('f1', 50, status: 'rejected', liters: 99, hour: 3)];
    final f = computeFlags(logs, const Vehicle());
    expect(codes(f, 'f1'), isEmpty);
    final s = computeStats(logs);
    expect(s.km, 100);
    expect(s.liters, 0);
  });

  test('stats: km by odometer span, km/L and cost/km, pending counted', () {
    final s = computeStats([
      trip('t1', 1000, 1150),
      fill('f1', 1050, liters: 10, price: 300),
      fill('f2', 1150, hour: 3, liters: 5, price: 300, status: 'approved'),
    ]);
    expect(s.km, 150);
    expect(s.liters, 15);
    expect(s.cost, 4500);
    expect(s.kmPerL, 10);
    expect(s.costPerKm, 30);
    expect(s.pendingFills, 1);
  });

  test('named place: inside radius only, closest wins', () {
    const places = [
      Place(id: 'p1', name: 'Home', lat: 24.8600, lng: 67.0000),
      Place(id: 'p2', name: 'Pump', lat: 24.8605, lng: 67.0000, radiusM: 100),
    ];
    expect(placeName(const GeoPoint2(lat: 24.8604, lng: 67.0, acc: 5, mock: false), places), 'Pump');
    // 111 m from Home (inside 150 m), 166 m from Pump (outside its 100 m).
    expect(placeName(const GeoPoint2(lat: 24.8590, lng: 67.0, acc: 5, mock: false), places), 'Home');
    expect(placeName(const GeoPoint2(lat: 24.9000, lng: 67.0, acc: 5, mock: false), places), isNull);
  });
}
