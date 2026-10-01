import 'app_user.dart';

/// Where the signed-in person stands. The router sends each state to one screen.
sealed class Session {
  const Session();
}

/// Waiting for Firebase Auth or the first read of the user's profile.
class SessionLoading extends Session {
  const SessionLoading();
}

class SignedOut extends Session {
  const SignedOut();
}

/// Signed in, but the app can't be used: no role, disabled, or no profile.
class SessionBlocked extends Session {
  const SessionBlocked(this.message);
  final String message;
}

class SignedIn extends Session {
  const SignedIn(this.user);
  final AppUser user;

  /// Drivers must accept the location disclosure once before using the app.
  bool get needsLocationNotice => user.isDriver && !user.locationNoticeAccepted;
}
