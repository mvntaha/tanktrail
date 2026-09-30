import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import '../domain/session.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);

final authUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The current [Session]. Rebuilds whenever the Firebase user changes, then
/// follows that user's profile doc (served from the offline cache when there
/// is no internet, so drivers stay signed in all day).
final sessionProvider = StreamProvider<Session>((ref) {
  final auth = ref.watch(authUserProvider);
  final user = auth.value;
  if (auth.isLoading && user == null) return Stream.value(const SessionLoading());
  if (user == null) return Stream.value(const SignedOut());
  return ref.watch(authRepositoryProvider).watchSession(user.uid);
});

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<Session> watchSession(String uid) {
    return _db.doc('users/$uid').snapshots().map<Session>((snap) {
      if (!snap.exists) {
        // A cache miss while offline isn't proof the profile is missing.
        if (snap.metadata.isFromCache) return const SessionLoading();
        return const SessionBlocked('This account is not set up yet. Ask the admin.');
      }
      final user = AppUser.fromMap(uid, snap.data()!);
      if (!user.active) return const SessionBlocked('This account is disabled. Ask the admin.');
      if (user.role == null) return const SessionBlocked('This account has no role. Ask the admin.');
      return SignedIn(user);
    }).transform(
      StreamTransformer<Session, Session>.fromHandlers(
        handleError: (error, stack, sink) {
          // permission-denied here means the sign-in token has no valid role
          // claim (e.g. the role was set after this login).
          debugPrint('Profile read failed: $error');
          sink.add(const SessionBlocked(
            'This account has no access yet. Sign out and sign in again, '
            'or ask the admin.',
          ));
        },
      ),
    );
  }

  /// Records the one-time location notice. Not awaited on purpose: offline,
  /// Firestore applies it locally at once and syncs later, but the Future only
  /// completes after the server confirms.
  void acceptLocationNotice(String uid) {
    _db
        .doc('users/$uid')
        .update({'locationNoticeAcceptedAt': FieldValue.serverTimestamp()})
        .catchError((Object e) => debugPrint('Notice sync failed: $e'));
  }
}

/// User-facing text for sign-in errors.
String signInErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' =>
        'Wrong email or password.',
      'user-disabled' => 'This account is disabled. Ask the admin.',
      'too-many-requests' => 'Too many attempts. Wait a few minutes and try again.',
      'network-request-failed' => 'No internet. Signing in needs a connection the first time.',
      _ => 'Sign-in failed (${error.code}).',
    };
  }
  return 'Sign-in failed. Try again.';
}
