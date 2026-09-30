import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/auth_repository.dart';

/// Asks before signing out. Signing back in needs internet, and drivers are
/// often offline, so an accidental tap would lock them out until they reconnect.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You will need internet to sign in again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
      ],
    ),
  );
  if (ok == true) await ref.read(authRepositoryProvider).signOut();
}
