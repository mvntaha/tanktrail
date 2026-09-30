import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';
import 'sign_out.dart';

/// Mandatory one-time disclosure before a driver can use the app.
class LocationNoticeScreen extends ConsumerWidget {
  const LocationNoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final uid = session is SignedIn ? session.user.uid : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.location_on_rounded, size: 64, color: t.primary),
              const SizedBox(height: 24),
              Text(
                'Location notice',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.foreground),
              ),
              const SizedBox(height: 16),
              Text(
                'This app records your location when you log a trip or a fill.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, height: 1.4, color: t.foreground),
              ),
              const SizedBox(height: 16),
              Text(
                'Location is taken only at those moments, never in the background. '
                'Only the admin can see it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.4, color: t.mutedForeground),
              ),
              const Spacer(),
              FilledButton(
                onPressed: uid == null ? null : () => ref.read(authRepositoryProvider).acceptLocationNotice(uid),
                child: const Text('I understand'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => confirmSignOut(context, ref), child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
