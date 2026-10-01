import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/features/admin/data/geocode_service.dart';

void main() {
  test('short address picks readable parts', () {
    expect(
      GeocodeService.shortAddress({
        'display_name': 'long, very long, Karachi Division, Sindh, 75400, Pakistan',
        'address': {'road': 'Shahrah-e-Faisal', 'suburb': 'PECHS', 'city': 'Karachi', 'country': 'Pakistan'},
      }),
      'Shahrah-e-Faisal, PECHS, Karachi',
    );
    expect(
      GeocodeService.shortAddress({
        'address': {'amenity': 'PSO Fuel Station', 'road': 'Main Road', 'town': 'Hub'},
      }),
      'PSO Fuel Station, Main Road, Hub',
    );
    expect(GeocodeService.shortAddress({'display_name': 'A, B, C, D'}), 'A, B, C');
  });

  test('nearby points share one cache key (~11 m grid)', () {
    expect(GeocodeService.key(24.860012, 67.000049), GeocodeService.key(24.860031, 67.000021));
    expect(GeocodeService.key(24.8600, 67.0), isNot(GeocodeService.key(24.8602, 67.0)));
  });
}
