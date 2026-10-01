import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/admin_repository.dart';
import '../domain/admin_log.dart';
import 'admin_map.dart';

/// Named places (admin only). Logs inside a place's circle show its name.
/// Places can be renamed or moved but not deleted (nothing is ever deleted).
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final data = ref.watch(adminDataProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminPlaceNew, extra: const Place(id: '', name: '', lat: 0, lng: 0)),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add place'),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (data.places.isNotEmpty) ...[
                  AdminMap(
                    pins: [for (final p in data.places) MapPin(LatLng(p.lat, p.lng), p.name, colorIndex: 1)],
                    places: data.places,
                    height: 220,
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.places.isEmpty)
                  Text('No places yet. Add home, office or your usual pumps; '
                      'or open a log and tap "Name this place".',
                      style: TextStyle(color: t.mutedForeground, fontSize: 15, height: 1.4)),
                for (final p in data.places)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.place_rounded, color: t.chart[1]),
                    title: Text(p.name),
                    subtitle: Text('${p.radiusM.round()} m radius'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.adminPlaceNew, extra: p),
                  ),
              ],
            ),
    );
  }
}

/// Add or change one place: tap the map to set the centre, choose a radius.
class PlaceEditScreen extends ConsumerStatefulWidget {
  const PlaceEditScreen({super.key, required this.place});
  final Place place;

  @override
  ConsumerState<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends ConsumerState<PlaceEditScreen> {
  late final _name = TextEditingController(text: widget.place.name);
  late LatLng? _at = widget.place.lat == 0 && widget.place.lng == 0 ? null : LatLng(widget.place.lat, widget.place.lng);
  late double _radius = widget.place.radiusM;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final at = _at;
    if (at == null || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).savePlace(
            Place(id: widget.place.id, name: _name.text.trim(), lat: at.latitude, lng: at.longitude, radiusM: _radius),
          );
      ref.invalidate(adminDataProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final at = _at;
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.id.isEmpty ? 'New place' : 'Edit place')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Home, PSO Main Road'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(at == null ? 'Tap the map to set the place.' : 'Tap the map to move it.',
              style: TextStyle(color: t.mutedForeground)),
          const SizedBox(height: 8),
          AdminMap(
            height: 300,
            pins: [if (at != null) MapPin(at, _name.text.isEmpty ? 'Place' : _name.text, colorIndex: 1)],
            places: [if (at != null) Place(id: '', name: '', lat: at.latitude, lng: at.longitude, radiusM: _radius)],
            onTap: (p) => setState(() => _at = p),
          ),
          const SizedBox(height: 16),
          Text('Radius: ${_radius.round()} m', style: TextStyle(color: t.foreground, fontWeight: FontWeight.w600)),
          Slider(
            value: _radius,
            min: 50,
            max: 1000,
            divisions: 19,
            label: '${_radius.round()} m',
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || at == null || _name.text.trim().isEmpty ? null : _save,
            child: const Text('Save place'),
          ),
        ],
      ),
    );
  }
}
