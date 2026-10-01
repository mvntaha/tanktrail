const fuelTypes = ['petrol', 'diesel', 'cng', 'other'];
const fuelTypeLabels = {'petrol': 'Petrol', 'diesel': 'Diesel', 'cng': 'CNG', 'other': 'Other'};
const paidByLabels = {'company_cash': 'Company cash', 'own': 'My own money'};

/// A fuel fill as the app shows it (no coordinates: drivers never see locations).
class FuelLog {
  const FuelLog({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.odometer,
    required this.liters,
    required this.pricePerL,
    required this.total,
    required this.fuelType,
    required this.paidBy,
    required this.capturedAtDevice,
    required this.status,
  });

  final String id;
  final String driverId;
  final String driverName;
  final int odometer;
  final double liters;
  final double pricePerL;

  /// Rupees.
  final double total;
  final String fuelType;
  final String paidBy;
  final DateTime capturedAtDevice;

  /// pending | approved | rejected
  final String status;
}

/// Liters x price, rounded to paisa (2 decimals), as the pump shows it.
double suggestTotal(double liters, double pricePerL) => (liters * pricePerL * 100).round() / 100;

/// True when the typed total roughly equals liters x price. Pumps round, so
/// allow 1 rupee or 0.5%, whichever is larger. Used for a soft warning only.
bool amountsConsistent(double liters, double pricePerL, double total) {
  final expected = liters * pricePerL;
  final tolerance = (expected * 0.005).clamp(1.0, double.infinity);
  return (expected - total).abs() <= tolerance;
}
