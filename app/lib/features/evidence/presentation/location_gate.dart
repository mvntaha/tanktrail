import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/location_service.dart';

/// Returns true only when location is on and allowed. Otherwise explains what
/// to fix, opens the right setting, and checks again. Capture is never allowed
/// without location.
Future<bool> ensureLocation(BuildContext context, WidgetRef ref) async {
  final service = ref.read(locationServiceProvider);
  while (true) {
    final problem = await service.ensureReady();
    if (problem == null) return true;
    if (!context.mounted) return false;

    final (title, body, action) = switch (problem) {
      LocationProblem.serviceOff => (
          'Turn on location',
          'Location is off. TankTrail needs it to record where this log happens.',
          'Open location settings',
        ),
      LocationProblem.denied => (
          'Allow location',
          'TankTrail needs location permission to record where this log happens.',
          'Allow',
        ),
      LocationProblem.deniedForever => (
          'Allow location in settings',
          'Location permission was blocked. Open app settings > Permissions > Location '
              'and choose "Allow only while using the app".',
          'Open app settings',
        ),
    };

    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (go != true) return false;
    await service.openFix(problem);
  }
}
