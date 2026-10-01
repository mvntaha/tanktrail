import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/session.dart';
import '../../features/auth/presentation/location_notice_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/status_screens.dart';
import '../../features/feed/presentation/driver_home_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const blocked = '/blocked';
  static const notice = '/notice';
  static const driver = '/driver';
  static const admin = '/admin';
}

/// The one route each session state is allowed to be on (plus sub-routes,
/// which later milestones add under /driver and /admin).
String homeFor(Session session) => switch (session) {
      SessionLoading() => Routes.splash,
      SignedOut() => Routes.login,
      SessionBlocked() => Routes.blocked,
      SignedIn(:final user) when user.isAdmin => Routes.admin,
      final SignedIn s when s.needsLocationNotice => Routes.notice,
      SignedIn() => Routes.driver,
    };

final routerProvider = Provider<GoRouter>((ref) {
  // Bridges Riverpod -> go_router: re-runs redirect whenever the session changes.
  final session = ValueNotifier<Session>(const SessionLoading());
  ref.listen(
    sessionProvider,
    (_, next) => session.value = next.value ?? const SessionLoading(),
    fireImmediately: true,
  );
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final home = homeFor(session.value);
      final at = state.matchedLocation;
      return (at == home || at.startsWith('$home/')) ? null : home;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.blocked, builder: (_, _) => const BlockedScreen()),
      GoRoute(path: Routes.notice, builder: (_, _) => const LocationNoticeScreen()),
      GoRoute(path: Routes.driver, builder: (_, _) => const DriverHomeScreen()),
      GoRoute(path: Routes.admin, builder: (_, _) => const AdminHomeScreen()),
    ],
  );
});
