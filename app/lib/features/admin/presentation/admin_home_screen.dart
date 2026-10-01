import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';
import '../data/admin_repository.dart';
import '../domain/admin_log.dart';
import '../domain/flags.dart';

/// Admin dashboard: window totals, then logs that need review (or all).
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  bool _onlyNeedsReview = true;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final name = session is SignedIn ? session.user.name : '';
    final days = ref.watch(adminWindowDaysProvider);
    final data = ref.watch(adminDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TankTrail Admin'),
        actions: [
          IconButton(tooltip: 'Vehicle', icon: const Icon(Icons.directions_car_rounded), onPressed: () => context.push(Routes.adminVehicle)),
          IconButton(tooltip: 'Places', icon: const Icon(Icons.place_rounded), onPressed: () => context.push(Routes.adminPlaces)),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout_rounded), onPressed: () => confirmSignOut(context, ref)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDataProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Hi $name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: t.foreground)),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('Last 7 days')),
                ButtonSegment(value: 30, label: Text('Last 30 days')),
              ],
              selected: {days},
              onSelectionChanged: (s) => ref.read(adminWindowDaysProvider.notifier).set(s.first),
            ),
            const SizedBox(height: 16),
            ...switch (data) {
              AsyncData(value: final d) => _content(context, d),
              AsyncError(:final error) => [
                  Text('Could not load: $error', style: TextStyle(color: t.destructive)),
                ],
              _ => [const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AdminData d) {
    final t = context.tokens;
    final s = d.stats;
    final needs = d.logs.where((l) => l.needsReview || (d.flags[l.id]!.isNotEmpty && !l.flagsHandled)).toList();
    final shown = _onlyNeedsReview ? needs : d.logs;

    return [
      if (!d.vehicle.isSet)
        _Banner(
          text: 'Set up the vehicle (name, plate, and optionally tank size, km/L, petrol price) to turn on more checks.',
          onTap: () => context.push(Routes.adminVehicle),
        ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Stat(label: 'Distance', value: s.km == null ? '–' : formatKm(s.km!)),
          _Stat(label: 'Fuel', value: '${s.liters.toStringAsFixed(1)} L'),
          _Stat(label: 'Cost', value: 'Rs ${formatThousands(s.cost.round())}'),
          _Stat(label: 'Efficiency', value: s.kmPerL == null ? '–' : '${s.kmPerL!.toStringAsFixed(1)} km/L'),
          _Stat(label: 'Cost per km', value: s.costPerKm == null ? '–' : 'Rs ${s.costPerKm!.toStringAsFixed(1)}'),
        ],
      ),
      if (s.pendingFills > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Includes ${s.pendingFills} fill(s) still pending review. Rejected fills are excluded.',
              style: TextStyle(fontSize: 13, color: t.mutedForeground)),
        ),
      const SizedBox(height: 22),
      Row(
        children: [
          ChoiceChip(
            label: Text('Needs attention (${needs.length})'),
            selected: _onlyNeedsReview,
            onSelected: (_) => setState(() => _onlyNeedsReview = true),
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: Text('All (${d.logs.length})'),
            selected: !_onlyNeedsReview,
            onSelected: (_) => setState(() => _onlyNeedsReview = false),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        Text(_onlyNeedsReview ? 'Nothing needs your attention.' : 'No logs in this period.',
            style: TextStyle(color: t.mutedForeground, fontSize: 15)),
      for (final l in shown) ...[
        AdminLogTile(log: l, flags: d.flags[l.id]!, onTap: () => context.push(Routes.adminLog(l.id))),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: t.accent,
        borderRadius: BorderRadius.circular(t.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(t.radiusSm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: t.accentForeground),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: TextStyle(color: t.accentForeground, fontSize: 14, height: 1.35))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: t.mutedForeground)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: t.cardForeground)),
        ],
      ),
    );
  }
}

/// One log in an admin list: what, who, when, status and flag count.
class AdminLogTile extends StatelessWidget {
  const AdminLogTile({super.key, required this.log, required this.flags, required this.onTap});
  final AdminLog log;
  final List<Flag> flags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = log;
    final title = l.isTrip
        ? (l.tripOpen ? 'Trip in progress' : 'Trip ${formatKm((l.endOdo ?? 0) - (l.startOdo ?? 0))}')
        : 'Fill Rs ${formatThousands((l.total ?? 0).round())} · ${(l.liters ?? 0).toStringAsFixed(2)} L';
    final status = l.isTrip ? (l.reviewed ? 'Reviewed' : (l.tripOpen ? 'Open' : 'Not reviewed')) : switch (l.status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };
    final worst = flags.isEmpty ? null : flags.map((f) => f.level.index).reduce((a, b) => a < b ? a : b);
    final (flagBg, flagFg) = switch (worst) {
      0 => (t.destructive, t.destructiveForeground),
      1 => (t.chart[3], t.primaryForeground),
      _ => (t.muted, t.mutedForeground),
    };

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(t.radius), border: Border.all(color: t.border)),
          child: Row(
            children: [
              Icon(l.isTrip ? Icons.route_rounded : Icons.local_gas_station_rounded, color: t.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.cardForeground)),
                    Text('${l.driverName} · ${formatWhen(l.deviceTime)} · $status${l.edited ? ' · edited' : ''}',
                        style: TextStyle(fontSize: 13, color: t.mutedForeground)),
                  ],
                ),
              ),
              if (flags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: flagBg, borderRadius: BorderRadius.circular(t.radiusSm)),
                  child: Text('${flags.length} flag${flags.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: flagFg)),
                ),
              Icon(Icons.chevron_right_rounded, color: t.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
