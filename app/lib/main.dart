import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/firebase/firebase_init.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  // ProviderScope holds all Riverpod state for the app.
  runApp(const ProviderScope(child: TankTrailApp()));
}

class TankTrailApp extends ConsumerWidget {
  const TankTrailApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Drivers' logs upload in the background while they are signed in.
    ref.listen(sessionProvider, (_, next) {
      final s = next.value;
      if (s is SignedIn && s.user.isDriver) ref.read(syncServiceProvider).start();
    });

    return MaterialApp.router(
      title: 'TankTrail',
      debugShowCheckedModeBanner: false,
      // Light theme only for now (dark tokens exist but are not wired).
      theme: buildAppTheme(AppTokens.light),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
