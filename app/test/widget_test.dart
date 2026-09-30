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
