import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart' show SyncState;
import '../../../core/router/app_router.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/domain/trip.dart';
import '../data/feed_repository.dart';
import 'feed_card.dart';

/// Driver home: trip and fuel actions on top, then the shared feed of
/// everyone's logs (like a group chat, without any locations).
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final me = session is SignedIn ? session.user : null;
    final openTrip = ref.watch(myOpenTripProvider);
    final feed = ref.watch(feedProvider);
    final older = ref.watch(olderPagesProvider);
    final syncs = ref.watch(logSyncProvider).value ?? const {};

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
      body: RefreshIndicator(
        // Pulling down retries uploads; the feed itself is live.
        onRefresh: () => ref.read(syncServiceProvider).kick(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Hi ${me?.name ?? ''}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.foreground)),
            const SizedBox(height: 16),
            if (openTrip.value == null) const _OthersOpenTrips(),
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
            Text('Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
            const SizedBox(height: 10),
            ...switch (feed) {
              AsyncData(value: final entries) when entries.isEmpty => [
                  Text('No logs yet.', style: TextStyle(color: t.mutedForeground, fontSize: 15)),
                ],
              AsyncData(value: final entries) => [
                  for (final e in entries) ...[
                    FeedCard(
                      entry: e,
                      isMine: e.driverId == me?.uid,
                      // Own logs only, while pending/unreviewed, and not refused by the server.
                      onEdit: e.driverId == me?.uid && e.editable && syncs[e.id]?.state != SyncState.rejected
                          ? () => context.push(Routes.editLog, extra: e)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!older.done)
                    OutlinedButton(
                      onPressed: older.loading ? null : () => ref.read(olderPagesProvider.notifier).loadMore(),
                      child: Text(older.loading ? 'Loading...' : 'Load older'),
                    )
                  else
                    Center(child: Text('That\'s everything.', style: TextStyle(color: t.mutedForeground))),
                ],
              AsyncError() => [
                  Text('Feed unavailable right now. Your own logs are safe on this phone.',
                      style: TextStyle(color: t.mutedForeground)),
                ],
              _ => [const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))],
            },
          ],
        ),
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

/// Warns (never blocks) when someone else has a trip open.
class _OthersOpenTrips extends ConsumerWidget {
  const _OthersOpenTrips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final others = ref.watch(othersOpenTripsProvider).value ?? const [];
    if (others.isEmpty) return const SizedBox.shrink();
    final who = others
        .map((o) => o.startedAt == null ? o.driverName : '${o.driverName} (since ${formatWhen(o.startedAt!)})')
        .join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.secondary,
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: t.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open trip: $who. If you have the car now, you can still start yours.',
              style: TextStyle(fontSize: 14, height: 1.35, color: t.secondaryForeground),
            ),
          ),
        ],
      ),
    );
  }
}
