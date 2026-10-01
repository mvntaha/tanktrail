import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/admin_log.dart';

/// A labelled point on the admin map.
class MapPin {
  const MapPin(this.at, this.label, {this.colorIndex = 0});
  final LatLng at;
  final String label;

  /// Index into the chart colors.
  final int colorIndex;
}

/// OpenStreetMap tiles, used per the OSM tile policy: app-specific User-Agent,
/// visible attribution, cached (flutter_map's built-in cache honours the
/// server's cache headers), no bulk or offline downloading. Admin only.
TileLayer osmTiles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.tanktrail.app',
      tileProvider: NetworkTileProvider(headers: {'User-Agent': 'TankTrail/1.0 (com.tanktrail.app; admin review)'}),
    );

Widget osmAttribution() => const RichAttributionWidget(
      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
    );

class AdminMap extends StatelessWidget {
  const AdminMap({super.key, required this.pins, this.places = const [], this.height = 240, this.onTap});

  final List<MapPin> pins;
  final List<Place> places;
  final double height;
  final void Function(LatLng point)? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final points = pins.map((p) => p.at).toList();
    final fit = points.length >= 2
        ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 17)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radius),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.isNotEmpty ? points.first : const LatLng(24.8607, 67.0011),
            initialZoom: points.isNotEmpty ? 16 : 11,
            initialCameraFit: fit,
            onTap: onTap == null ? null : (_, p) => onTap!(p),
          ),
          children: [
            osmTiles(),
            CircleLayer(circles: [
              for (final p in places)
                CircleMarker(
                  point: LatLng(p.lat, p.lng),
                  radius: p.radiusM,
                  useRadiusInMeter: true,
                  color: t.chart[1].withValues(alpha: 0.15),
                  borderColor: t.chart[1],
                  borderStrokeWidth: 1.5,
                ),
            ]),
            MarkerLayer(markers: [
              for (final p in pins)
                Marker(
                  point: p.at,
                  width: 120,
                  height: 56,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(8), boxShadow: t.shadowSm),
                        child: Text(p.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.cardForeground)),
                      ),
                      Icon(Icons.location_on_rounded, color: t.chart[p.colorIndex % t.chart.length], size: 28),
                    ],
                  ),
                ),
            ]),
            osmAttribution(),
          ],
        ),
      ),
    );
  }
}
