import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

/// How far a log has got, for the small badge on each log.
class LogSync {
  const LogSync({required this.state, required this.uploaded, required this.files, this.error});

  /// The log's overall [SyncState] (for trips: the least advanced of start/end).
  final String state;
  final int uploaded;
  final int files;
  final String? error;

  String get label => switch (state) {
        SyncState.synced => 'Sent',
        SyncState.sent => 'Sending...',
        SyncState.rejected => 'Not accepted',
        _ when uploaded > 0 => 'Uploading $uploaded/$files',
        _ => 'Waiting to upload',
      };
}

/// Upload/sync state per log ID, kept live from the phone database.
final logSyncProvider = StreamProvider<Map<String, LogSync>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Re-read whenever any of the three tables changes (cheap: tens of rows).
  final trigger = db.customSelect('SELECT 1', readsFrom: {db.localTrips, db.localFuelLogs, db.localEvidence}).watch();
  return trigger.asyncMap((_) async {
    final counts = <String, (int, int)>{};
    for (final e in await db.select(db.localEvidence).get()) {
      final (up, all) = counts[e.logId] ?? (0, 0);
      counts[e.logId] = (up + (e.uploadState == UploadState.uploaded ? 1 : 0), all + 1);
    }
    LogSync make(String id, String state, String? error) {
      final (up, all) = counts[id] ?? (0, 0);
      return LogSync(state: state, uploaded: up, files: all, error: error);
    }

    const rank = [SyncState.rejected, SyncState.local, SyncState.sent, SyncState.synced];
    return {
      for (final t in await db.select(db.localTrips).get())
        t.id: make(
          t.id,
          // An open trip only has a start to send; a closed one needs both parts.
          t.status == 'open'
              ? t.startSync
              : rank[[rank.indexOf(t.startSync), rank.indexOf(t.endSync)].reduce((a, b) => a < b ? a : b)],
          t.syncError,
        ),
      for (final f in await db.select(db.localFuelLogs).get()) f.id: make(f.id, f.sync, f.syncError),
    };
  });
});

/// Number of this driver's logs not yet confirmed by the server.
final unsyncedCountProvider = StreamProvider.family<int, String>((ref, uid) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        "SELECT (SELECT COUNT(*) FROM local_trips WHERE driver_id = ?1 AND "
        "(start_sync != 'synced' OR (status = 'closed' AND end_sync != 'synced'))) + "
        "(SELECT COUNT(*) FROM local_fuel_logs WHERE driver_id = ?1 AND sync != 'synced') AS n",
        variables: [Variable.withString(uid)],
        readsFrom: {db.localTrips, db.localFuelLogs},
      )
      .watchSingle()
      .map((r) => r.read<int>('n'));
});
