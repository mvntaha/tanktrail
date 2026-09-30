enum UserRole { driver, admin }

/// Profile from `users/{uid}` (written by backend/seed.js).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.locationNoticeAccepted,
  });

  final String uid;
  final String name;
  final String email;

  /// Null if the doc has no valid role (the rules would block this user anyway).
  final UserRole? role;
  final bool active;

  /// True once `locationNoticeAcceptedAt` exists. We check for the key, not the
  /// value: while offline a pending server timestamp reads as null, and the
  /// notice must not reappear just because the write hasn't synced yet.
  final bool locationNoticeAccepted;

  bool get isDriver => role == UserRole.driver;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: switch (map['role']) {
        'driver' => UserRole.driver,
        'admin' => UserRole.admin,
        _ => null,
      },
      active: map['active'] == true,
      locationNoticeAccepted: map.containsKey('locationNoticeAcceptedAt'),
    );
  }
}
