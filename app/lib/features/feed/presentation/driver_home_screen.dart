import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';

/// Driver home. Trips (M3), fuel logging (M4) and the feed (M6) come later.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final name = session is SignedIn ? session.user.name : '';

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
          const SizedBox(height: 4),
          Text('Driver', style: TextStyle(fontSize: 15, color: t.mutedForeground)),
          const SizedBox(height: 24),
          const _ComingSoon(icon: Icons.route_rounded, title: 'Trips', subtitle: 'Start and end trips'),
          const SizedBox(height: 12),
          const _ComingSoon(icon: Icons.local_gas_station_rounded, title: 'Fuel', subtitle: 'Log a fill'),
          const SizedBox(height: 12),
          const _ComingSoon(icon: Icons.forum_rounded, title: 'Feed', subtitle: 'Everyone\'s logs'),
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
        boxShadow: t.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(t.radiusSm)),
              child: Icon(icon, color: t.accentForeground, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
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
