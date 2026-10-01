import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/core/db/app_database.dart';
import 'package:tanktrail/core/router/app_router.dart';
import 'package:tanktrail/features/auth/data/auth_repository.dart';
import 'package:tanktrail/features/auth/domain/app_user.dart';
import 'package:tanktrail/features/auth/domain/session.dart';
import 'package:tanktrail/features/feed/data/feed_repository.dart';

SignedIn _as(String uid, UserRole role) => SignedIn(AppUser(
      uid: uid,
      name: uid,
      email: '$uid@example.com',
      role: role,
      active: true,
      locationNoticeAccepted: true,
    ));

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('sign in -> sign out -> sign in again: feed restarts, nothing stale', () async {
    final session = StreamController<Session>();
    final fs = FakeFirebaseFirestore();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await fs.doc('trips/t1').set({
      'driverId': 'ali',
      'driverName': 'Ali',
      'startOdo': 1,
      'status': 'open',
      'createdAt': Timestamp.now(),
      'startedAt': Timestamp.now(),
    });

    final c = ProviderContainer(overrides: [
      sessionProvider.overrideWith((ref) => session.stream),
      firestoreProvider.overrideWithValue(fs),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(feedProvider, (_, _) {});
    addTearDown(sub.close);

    session.add(_as('ali', UserRole.driver));
    await settle();
    expect(c.read(feedProvider).value?.map((e) => e.id), ['t1']);
    expect(homeFor(c.read(sessionProvider).value!), Routes.driver);

    session.add(const SignedOut());
    await settle();
    expect(c.read(currentUidProvider), isNull);
    expect(c.read(feedProvider).value, isEmpty); // listeners stopped, nothing shown
    expect(homeFor(c.read(sessionProvider).value!), Routes.login);

    session.add(_as('bilal', UserRole.driver)); // another driver on the same phone
    await settle();
    expect(c.read(feedProvider).value?.map((e) => e.id), ['t1']); // fresh, working listener
    expect(c.read(currentUidProvider), 'bilal');

    session.add(_as('boss', UserRole.admin));
    await settle();
    expect(homeFor(c.read(sessionProvider).value!), Routes.admin);
  });
}
