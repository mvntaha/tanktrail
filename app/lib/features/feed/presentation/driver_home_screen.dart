import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/domain/fuel_log.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/domain/trip.dart';

/// Driver home: trip controls and this driver's recent trips.
/// The shared feed of everyone's logs comes in M6.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final name = session is SignedIn ? session.user.name : '';
    final openTrip = ref.watch(myOpenTripProvider);
    final trips = ref.watch(myTripsProvider).value ?? const <Trip>[];
    final fills = ref.watch(myFillsProvider).value ?? const <FuelLog>[];

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
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.fuelNew),
            icon: const Icon(Icons.local_gas_station_rounded, size: 26),
            label: const Text('Log fuel'),
          ),
          const SizedBox(height: 28),
          Text('My recent fills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
          const SizedBox(height: 10),
          if (fills.isEmpty)
            Text('No fills yet.', style: TextStyle(color: t.mutedForeground, fontSize: 15))
          else
            for (final fill in fills.take(5)) ...[
              _FillTile(fill: fill),
              const SizedBox(height: 10),
            ],
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
              const _OnPhoneBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

class _FillTile extends StatelessWidget {
  const _FillTile({required this.fill});

  final FuelLog fill;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
                  'Rs ${fill.total.toStringAsFixed(0)}  ·  ${fill.liters.toStringAsFixed(2)} L',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.cardForeground),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatKm(fill.odometer)}  ·  ${paidByLabels[fill.paidBy]}',
                  style: TextStyle(fontSize: 14, color: t.mutedForeground),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatWhen(fill.capturedAtDevice), style: TextStyle(fontSize: 13, color: t.mutedForeground)),
              const SizedBox(height: 4),
              const _OnPhoneBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nothing uploads yet (M5); be honest about where the data is.
class _OnPhoneBadge extends StatelessWidget {
  const _OnPhoneBadge();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: t.muted, borderRadius: BorderRadius.circular(t.radiusSm)),
      child: Text('On phone', style: TextStyle(fontSize: 12, color: t.mutedForeground)),
    );
  }
}
