import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';
import 'sign_out.dart';

/// Shown while Firebase restores the session at app start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: context.tokens.primary)),
    );
  }
}

/// Signed in but not allowed in (no role, disabled, no profile).
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionProvider).value;
    final message = session is SessionBlocked ? session.message : 'This account cannot be used.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.block_rounded, size: 56, color: t.destructive),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, height: 1.4, color: t.foreground),
              ),
              const SizedBox(height: 32),
              OutlinedButton(onPressed: () => confirmSignOut(context, ref), child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
