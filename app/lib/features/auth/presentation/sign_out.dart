import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/sync/sync_status.dart';
import '../data/auth_repository.dart';
import '../domain/session.dart';

/// Asks before signing out. Signing back in needs internet, and drivers are
/// often offline, so an accidental tap would lock them out until they reconnect.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  // Logs still waiting to upload are sent with the signed-in account; after
  // signing out they can't be sent until this same driver signs in again.
  final session = ref.read(sessionProvider).value;
  final unsynced = session is SignedIn ? await ref.read(unsyncedCountProvider(session.user.uid).future) : 0;
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: Text(unsynced > 0
          ? '$unsynced of your logs are not uploaded yet. They stay on this phone and upload only '
              'after you sign in again. You will need internet to sign in.'
          : 'You will need internet to sign in again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
      ],
    ),
  );
  if (ok == true) await ref.read(authRepositoryProvider).signOut();
}
