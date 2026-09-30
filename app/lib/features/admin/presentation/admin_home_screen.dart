import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/sign_out.dart';

/// Admin home. Dashboard, reviews and settings arrive in M7, reports in M8.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final name = session is SignedIn ? session.user.name : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TankTrail Admin'),
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
          Text('Admin', style: TextStyle(fontSize: 15, color: t.mutedForeground)),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(t.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Reviews, flags, vehicle settings and reports will appear here.',
                style: TextStyle(fontSize: 16, height: 1.4, color: t.accentForeground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
