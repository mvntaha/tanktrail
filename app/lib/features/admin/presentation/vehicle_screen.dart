import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../fuel/domain/fuel_log.dart';
import '../data/admin_repository.dart';
import '../domain/admin_log.dart';

/// vehicle/main. Optional values may stay blank: the checks that need them
/// (price, tank size, km/L) stay off until they are filled in.
class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key});

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen> {
  final _name = TextEditingController();
  final _plate = TextEditingController();
  final _tank = TextEditingController();
  final _kmPerL = TextEditingController();
  final _price = TextEditingController();
  String _fuelType = 'petrol';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _plate, _tank, _kmPerL, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Vehicle v) {
    _loaded = true;
    _name.text = v.name;
    _plate.text = v.plate;
    _fuelType = v.fuelType;
    String n(double? x) => x == null ? '' : (x == x.roundToDouble() ? x.round().toString() : x.toString());
    _tank.text = n(v.tankCapacityL);
    _kmPerL.text = n(v.baselineKmPerL);
    _price.text = n(v.referencePricePerL);
  }

  double? _opt(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return v == null || v <= 0 ? null : v;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).saveVehicle(Vehicle(
            name: _name.text.trim(),
            plate: _plate.text.trim(),
            fuelType: _fuelType,
            tankCapacityL: _opt(_tank),
            baselineKmPerL: _opt(_kmPerL),
            referencePricePerL: _opt(_price),
          ));
      ref.invalidate(adminDataProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle saved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Widget _field(TextEditingController c, String label, {String? help, String? suffix, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        enabled: !_saving,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?'))] : null,
        decoration: InputDecoration(labelText: label, helperText: help, suffixText: suffix),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = ref.watch(adminDataProvider).value;
    if (data != null && !_loaded) _fill(data.vehicle);

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle')),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field(_name, 'Name', help: 'e.g. the car model'),
                _field(_plate, 'Number plate'),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final type in fuelTypes)
                      ChoiceChip(
                        label: Text(fuelTypeLabels[type]!),
                        selected: _fuelType == type,
                        onSelected: (_) => setState(() => _fuelType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Optional (leave blank if unsure; related checks stay off)',
                    style: TextStyle(fontSize: 14, color: t.mutedForeground)),
                const SizedBox(height: 10),
                _field(_tank, 'Tank size', suffix: 'L', number: true, help: 'Flags fills larger than the tank'),
                _field(_kmPerL, 'Typical km per litre', suffix: 'km/L', number: true,
                    help: 'Turns on expected-km checks (15% tolerance)'),
                _field(_price, 'Current price per litre', suffix: 'Rs', number: true,
                    help: 'Flags fills more than Rs 1 off. Update when the price changes.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving || _name.text.trim().isEmpty ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
