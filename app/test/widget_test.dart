import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tanktrail/core/router/app_router.dart';
import 'package:tanktrail/core/theme/app_theme.dart';
import 'package:tanktrail/core/theme/app_tokens.dart';
import 'package:tanktrail/features/auth/domain/app_user.dart';
import 'package:tanktrail/features/auth/domain/session.dart';
import 'package:tanktrail/features/auth/presentation/login_screen.dart';

AppUser _user({String role = 'driver', bool notice = false}) => AppUser.fromMap('u1', {
      'name': 'Ali',
      'email': 'ali@example.com',
      'role': role,
      'active': true,
      if (notice) 'locationNoticeAcceptedAt': null, // pending server timestamp
    });

void main() {
  group('AppUser.fromMap', () {
    test('parses role and notice key', () {
      final u = _user(notice: true);
      expect(u.role, UserRole.driver);
      expect(u.locationNoticeAccepted, isTrue);
    });
    test('unknown role becomes null', () {
      expect(_user(role: 'boss').role, isNull);
    });
  });

  group('homeFor routes each session to one screen', () {
    test('loading / signed out / blocked', () {
      expect(homeFor(const SessionLoading()), Routes.splash);
      expect(homeFor(const SignedOut()), Routes.login);
      expect(homeFor(const SessionBlocked('x')), Routes.blocked);
    });
    test('driver sees the notice until accepted, then driver home', () {
      expect(homeFor(SignedIn(_user())), Routes.notice);
      expect(homeFor(SignedIn(_user(notice: true))), Routes.driver);
    });
    test('admin goes straight to admin home (no notice)', () {
      expect(homeFor(SignedIn(_user(role: 'admin'))), Routes.admin);
    });
  });

  group('tokens match docs/design-tokens.css', () {
    final t = AppTokens.light;
    test('--shadow has both layers: 0 2px 28px + 0 1px 2px -1px, #4e5661 at 10%', () {
      expect(t.shadow, hasLength(2));
      expect(t.shadow[0].offset, const Offset(0, 2));
      expect(t.shadow[1].offset, const Offset(0, 1));
      expect(t.shadow[1].spreadRadius, -1);
      expect(t.shadow[0].color, const Color(0xFF4E5661).withValues(alpha: 0.10));
      expect(t.shadow2xs.single.color, const Color(0xFF4E5661).withValues(alpha: 0.05));
      expect(t.shadow2xl.single.color, const Color(0xFF4E5661).withValues(alpha: 0.25));
    });
    test('radius scale and key colors', () {
      expect([t.radiusSm, t.radiusMd, t.radiusLg, t.radiusXl], [20, 22, 24, 28]);
      expect(t.primary, const Color(0xFF297CEF));
      expect(t.sidebar, const Color(0xFFECEFF1));
      expect(AppTokens.dark.sidebarBorder, const Color(0xFF212429));
      expect(AppTokens.dark.destructiveForeground, const Color(0xFFFFFFFF));
    });
  });

  testWidgets('login screen shows email, password and sign-in button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: buildAppTheme(AppTokens.light), home: const LoginScreen()),
      ),
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });
}
