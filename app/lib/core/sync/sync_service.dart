import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/evidence/data/evidence_uploader.dart';
import '../config.dart';
import '../db/app_database.dart';

final evidenceUploaderProvider = Provider<EvidenceUploader>(
  (ref) => CloudinaryUploader(signerUrl: AppConfig.signerUrl),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final s = SyncService(
    db: ref.watch(appDatabaseProvider),
    firestore: ref.watch(firestoreProvider),
    currentUid: () => ref.read(firebaseAuthProvider).currentUser?.uid,
    uploader: ref.watch(evidenceUploaderProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

/// Moves logs from the phone to the server, in this order:
///   1. upload every evidence file (Cloudinary, via [EvidenceUploader]);
///   2. when ALL files of a log are uploaded, write the log + its private/geo
///      doc to Firestore in ONE batch (a trip's end only after its start);
///   3. confirm with the server that the write arrived.
/// Runs on app start, every few minutes while open, when the app comes back to
/// the foreground, and right after a log is saved. Safe to run repeatedly.
class SyncService with WidgetsBindingObserver {
  SyncService({required this.db, required this.firestore, required this.currentUid, required this.uploader});

  final AppDatabase db;
  final FirebaseFirestore firestore;
  /// The signed-in user's ID, or null (a function so tests need no Firebase Auth).
  final String? Function() currentUid;
  final EvidenceUploader uploader;

  bool _started = false;
  bool _running = false;
  bool _again = false;
  Timer? _timer;
  StreamSubscription<UploadResult>? _sub;

  /// Last problem, for a small hint in the UI (e.g. "no internet").
  final lastError = ValueNotifier<String?>(null);

  Future<void> start() async {
    if (_started) return kick();
    _started = true;
    _sub = uploader.results.listen(_onResult);
    await uploader.start();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 3), (_) => kick());
    await kick();
  }

  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) kick();
  }

  /// Runs a sync pass now (or right after the current one finishes).
  Future<void> kick() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _pass();
      } while (_again);
    } catch (e, st) {
      debugPrint('Sync pass failed: $e\n$st');
    } finally {
      _running = false;
    }
  }

  Future<void> _pass() async {
    final uid = currentUid();
    if (uid == null) return;
    final myLogs = await _myLogIds(uid);
    if (myLogs.isEmpty) return;

    await _uploadPending(myLogs);
    await _commitReadyTrips(uid);
    await _commitReadyFills(uid);
    await _confirmSent(uid);
  }

  Future<Set<String>> _myLogIds(String uid) async {
    final trips = await (db.selectOnly(db.localTrips)
          ..addColumns([db.localTrips.id])
          ..where(db.localTrips.driverId.equals(uid)))
        .map((r) => r.read(db.localTrips.id)!)
        .get();
    final fills = await (db.selectOnly(db.localFuelLogs)
          ..addColumns([db.localFuelLogs.id])
          ..where(db.localFuelLogs.driverId.equals(uid)))
        .map((r) => r.read(db.localFuelLogs.id)!)
        .get();
    return {...trips, ...fills};
  }

  // ---------- 1. uploads ----------

  Future<void> _uploadPending(Set<String> myLogs) async {
    // An upload we marked as running but the uploader no longer knows about
    // (e.g. phone restarted) goes back to pending. Re-uploading is harmless:
    // the signed public_id and overwrite=false return the existing file.
    final running = await (db.select(db.localEvidence)
          ..where((e) => e.uploadState.equals(UploadState.uploading) & e.logId.isIn(myLogs)))
        .get();
    for (final e in running) {
      if (!await uploader.isActive(e.id)) await _setUpload(e.id, UploadState.pending);
    }

    final pending = await (db.select(db.localEvidence)
          ..where((e) => e.uploadState.equals(UploadState.pending) & e.logId.isIn(myLogs))
          ..orderBy([(e) => OrderingTerm.asc(e.capturedAtDevice)]))
        .get();
    if (pending.isEmpty) return;

    final toSend = <PendingUpload>[];
    for (final e in pending) {
      if (await uploader.isActive(e.id)) {
        await _setUpload(e.id, UploadState.uploading);
      } else {
        toSend.add(PendingUpload(mediaId: e.id, logId: e.logId, type: e.type, filePath: e.filePath));
      }
    }
    if (toSend.isEmpty) return;
    try {
      await uploader.enqueue(toSend);
      for (final p in toSend) {
        await _setUpload(p.mediaId, UploadState.uploading);
      }
      lastError.value = null;
    } catch (e) {
      // Usually no internet. Everything stays pending; the next pass retries.
      lastError.value = 'Waiting for internet';
      debugPrint('Signing/enqueue failed: $e');
    }
  }

  Future<void> _setUpload(String mediaId, String state, {String? error}) {
    return (db.update(db.localEvidence)..where((e) => e.id.equals(mediaId))).write(
      LocalEvidenceCompanion(uploadState: Value(state), uploadError: Value(error)),
    );
  }

  Future<void> _onResult(UploadResult r) async {
    if (r.ok) {
      await (db.update(db.localEvidence)..where((e) => e.id.equals(r.mediaId))).write(
        LocalEvidenceCompanion(
          uploadState: const Value(UploadState.uploaded),
          url: Value(r.url),
          publicId: Value(r.publicId),
          uploadError: const Value(null),
        ),
      );
      unawaited(kick()); // maybe a log is now complete
    } else {
      // Back to pending with a fresh signature next pass (signatures expire after 1 h).
      await _setUpload(r.mediaId, UploadState.pending, error: r.error);
    }
  }

  // ---------- 2. Firestore writes ----------

  Future<List<LocalEvidenceData>> _evidence(String logId, String phase) {
    return (db.select(db.localEvidence)
          ..where((e) => e.logId.equals(logId) & e.phase.equals(phase))
          ..orderBy([(e) => OrderingTerm.asc(e.capturedAtDevice)]))
        .get();
  }

  static bool _allUploaded(List<LocalEvidenceData> ev) =>
      ev.isNotEmpty && ev.every((e) => e.uploadState == UploadState.uploaded && e.url != null);

  /// Public evidence item: no coordinates, no OCR.
  static Map<String, dynamic> _publicItem(LocalEvidenceData e) => {
        'type': e.type,
        'url': e.url,
        'publicId': e.publicId,
        'sha256': e.sha256,
        'capturedAtDevice': Timestamp.fromDate(e.capturedAtDevice),
        if (e.durationSec != null) 'durationSec': e.durationSec,
      };

  /// Admin-only per-file details for private/geo: where it was taken and what
  /// OCR read (rules check only that this is a list).
  static Map<String, dynamic> _privateItem(LocalEvidenceData e) => {
        'mediaId': e.id,
        'type': e.type,
        'lat': e.lat,
        'lng': e.lng,
        'acc': e.acc,
        'mock': e.mock,
        if (e.ocrText != null) 'ocrText': e.ocrText,
      };

  static Map<String, dynamic> _loc(double lat, double lng, double acc, bool mock) =>
      {'lat': lat, 'lng': lng, 'acc': acc, 'mock': mock};

  Future<void> _commitReadyTrips(String uid) async {
    final trips = await (db.select(db.localTrips)..where((t) => t.driverId.equals(uid))).get();
    for (final t in trips) {
      final tripRef = firestore.collection('trips').doc(t.id);
      final geoRef = tripRef.collection('private').doc('geo');

      if (t.startSync == SyncState.local) {
        final ev = await _evidence(t.id, 'start');
        if (!_allUploaded(ev)) continue;
        final batch = firestore.batch()
          ..set(tripRef, {
            'driverId': t.driverId,
            'driverName': t.driverName,
            'startOdo': t.startOdo,
            'startedAt': Timestamp.fromDate(t.startedAt),
            'startEvidence': ev.map(_publicItem).toList(),
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'open',
            'edited': false,
          })
          ..set(geoRef, {
            'startLoc': _loc(t.startLat, t.startLng, t.startAcc, t.startMock),
            'startEvidenceLocs': ev.map(_privateItem).toList(),
          });
        await _send(batch, (state, error) => _setTrip(t.id, start: state, error: error));
        continue; // the end goes in a later pass, after the start
      }

      final startOnServer = t.startSync == SyncState.sent || t.startSync == SyncState.synced;
      if (t.status == 'closed' && startOnServer && t.endSync == SyncState.local) {
        final ev = await _evidence(t.id, 'end');
        if (!_allUploaded(ev)) continue;
        final batch = firestore.batch()
          ..update(tripRef, {
            'status': 'closed',
            'endOdo': t.endOdo,
            'endedAt': Timestamp.fromDate(t.endedAt!),
            'endEvidence': ev.map(_publicItem).toList(),
            'closedAt': FieldValue.serverTimestamp(),
          })
          ..update(geoRef, {
            'endLoc': _loc(t.endLat!, t.endLng!, t.endAcc!, t.endMock!),
            'endEvidenceLocs': ev.map(_privateItem).toList(),
          });
        await _send(batch, (state, error) => _setTrip(t.id, end: state, error: error));
      }
    }
  }

  Future<void> _commitReadyFills(String uid) async {
    final fills = await (db.select(db.localFuelLogs)
          ..where((f) => f.driverId.equals(uid) & f.sync.equals(SyncState.local)))
        .get();
    for (final f in fills) {
      final ev = await _evidence(f.id, 'fill');
      if (ev.length < 3 || !_allUploaded(ev)) continue;
      // Fixed order for the feed: odometer, pump photo, video.
      const order = {'odometer': 0, 'pump': 1, 'video': 2};
      ev.sort((a, b) => (order[a.type] ?? 9).compareTo(order[b.type] ?? 9));
      final ref = firestore.collection('fuelLogs').doc(f.id);
      final batch = firestore.batch()
        ..set(ref, {
          'driverId': f.driverId,
          'driverName': f.driverName,
          'odometer': f.odometer,
          'liters': f.liters,
          'pricePerL': f.pricePerL,
          'total': f.total,
          'fuelType': f.fuelType,
          'paidBy': f.paidBy,
          'evidence': ev.map(_publicItem).toList(),
          'capturedAtDevice': Timestamp.fromDate(f.capturedAtDevice),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'edited': false,
        })
        ..set(ref.collection('private').doc('geo'), {
          'loc': _loc(f.lat, f.lng, f.acc, f.mock),
          'evidenceLocs': ev.map(_privateItem).toList(),
        });
      await _send(batch, (state, error) => _setFill(f.id, state, error: error));
    }
  }

  /// Marks the log 'sent' and hands the batch to Firestore's offline queue,
  /// which persists it and delivers it even after an app restart. The server's
  /// answer (when it comes) moves it to 'synced' or 'rejected'.
  Future<void> _send(WriteBatch batch, Future<void> Function(String state, String? error) mark) async {
    await mark(SyncState.sent, null);
    unawaited(batch.commit().then(
      (_) => mark(SyncState.synced, null),
      onError: (Object e) {
        // Rules refused it. Nothing is lost: the log and files stay on the phone.
        final msg = e is FirebaseException ? '${e.code}: ${e.message}' : '$e';
        debugPrint('Firestore rejected a write: $msg');
        return mark(SyncState.rejected, msg);
      },
    ));
  }

  Future<void> _setTrip(String id, {String? start, String? end, String? error}) {
    return (db.update(db.localTrips)..where((t) => t.id.equals(id))).write(LocalTripsCompanion(
      startSync: start == null ? const Value.absent() : Value(start),
      endSync: end == null ? const Value.absent() : Value(end),
      syncError: Value(error),
    ));
  }

  Future<void> _setFill(String id, String state, {String? error}) {
    return (db.update(db.localFuelLogs)..where((f) => f.id.equals(id)))
        .write(LocalFuelLogsCompanion(sync: Value(state), syncError: Value(error)));
  }

  // ---------- 3. confirm ----------

  /// 'sent' logs whose server answer we missed (app was closed): once Firestore
  /// has flushed its queue, look them up on the server.
  Future<void> _confirmSent(String uid) async {
    final sentTrips = await (db.select(db.localTrips)
          ..where((t) =>
              t.driverId.equals(uid) & (t.startSync.equals(SyncState.sent) | t.endSync.equals(SyncState.sent))))
        .get();
    final sentFills = await (db.select(db.localFuelLogs)
          ..where((f) => f.driverId.equals(uid) & f.sync.equals(SyncState.sent)))
        .get();
    if (sentTrips.isEmpty && sentFills.isEmpty) return;

    try {
      // Resolves only when the queue is empty, i.e. we are online and it's sent.
      await firestore.waitForPendingWrites().timeout(const Duration(seconds: 20));
    } catch (_) {
      return; // still offline (timeout) or not possible right now; try next pass
    }

    for (final t in sentTrips) {
      final snap = await firestore.collection('trips').doc(t.id).get(const GetOptions(source: Source.server));
      final data = snap.data();
      await _setTrip(
        t.id,
        // Missing on the server after the queue flushed = it never got there; send again.
        start: t.startSync == SyncState.sent ? (snap.exists ? SyncState.synced : SyncState.local) : null,
        end: t.endSync == SyncState.sent ? (data?['status'] == 'closed' ? SyncState.synced : SyncState.local) : null,
      );
    }
    for (final f in sentFills) {
      final snap = await firestore.collection('fuelLogs').doc(f.id).get(const GetOptions(source: Source.server));
      await _setFill(f.id, snap.exists ? SyncState.synced : SyncState.local);
    }
  }
}
