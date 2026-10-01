import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/domain/trip.dart';

/// Driver home: trip controls and this driver's recent trips.
/// Fuel logging (M4) and the shared feed (M6) come later.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final name = session is SignedIn ? session.user.name : '';
    final openTrip = ref.watch(myOpenTripProvider);
    final trips = ref.watch(myTripsProvider).value ?? const <Trip>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TankTrail'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => confirmSignOut(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Hi $name', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.foreground)),
          const SizedBox(height: 20),
          switch (openTrip) {
            AsyncData(value: final trip?) => _OpenTripCard(trip: trip),
            AsyncData() => FilledButton.icon(
                onPressed: () => context.push(Routes.tripStart),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start trip'),
              ),
            _ => const SizedBox(height: 56),
          },
          const SizedBox(height: 12),
          const _ComingSoon(icon: Icons.local_gas_station_rounded, title: 'Fuel', subtitle: 'Log a fill'),
          const SizedBox(height: 28),
          Text('My recent trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
          const SizedBox(height: 10),
          if (trips.isEmpty)
            Text('No trips yet.', style: TextStyle(color: t.mutedForeground, fontSize: 15))
          else
            for (final trip in trips) ...[
              _TripTile(trip: trip),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _OpenTripCard extends StatelessWidget {
  const _OpenTripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: BorderRadius.circular(t.radius),
        boxShadow: t.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: t.accentForeground),
              const SizedBox(width: 8),
              Text('Trip in progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.accentForeground)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Started ${formatWhen(trip.startedAt)} at ${formatKm(trip.startOdo)}',
            style: TextStyle(fontSize: 15, color: t.accentForeground),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(Routes.tripEnd(trip.id)),
            icon: const Icon(Icons.stop_rounded, size: 28),
            label: const Text('End trip'),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final km = trip.distanceKm;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.isOpen ? 'In progress' : (km == null ? '' : formatKm(km)),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.cardForeground),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.isOpen
                      ? 'From ${formatKm(trip.startOdo)}'
                      : '${formatKm(trip.startOdo)} → ${formatKm(trip.endOdo!)}',
                  style: TextStyle(fontSize: 14, color: t.mutedForeground),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatWhen(trip.startedAt), style: TextStyle(fontSize: 13, color: t.mutedForeground)),
              const SizedBox(height: 4),
              // Nothing uploads yet (M5); be honest about where the data is.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: t.muted, borderRadius: BorderRadius.circular(t.radiusSm)),
                child: Text('On phone', style: TextStyle(fontSize: 12, color: t.mutedForeground)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: t.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: t.secondary, borderRadius: BorderRadius.circular(t.radiusSm)),
              child: Icon(icon, color: t.secondaryForeground, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.cardForeground)),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: t.mutedForeground)),
                ],
              ),
            ),
            Text('Soon', style: TextStyle(fontSize: 13, color: t.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
