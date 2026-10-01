import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/ids.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../domain/feed_entry.dart';

/// Feed page size. Live listeners are limited to the first page, so reads stay
/// small on the free quota; older pages are one-off reads.
const feedPageSize = 20;

typedef FeedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(ref.watch(firestoreProvider), ref.watch(appDatabaseProvider)),
);

final _firstTripsProvider = StreamProvider<FeedDocs>((ref) => ref.watch(feedRepositoryProvider).firstPage('trips'));
final _firstFillsProvider = StreamProvider<FeedDocs>((ref) => ref.watch(feedRepositoryProvider).firstPage('fuelLogs'));

/// Pages loaded with "Load older".
class OlderPages {
  const OlderPages({this.trips = const [], this.fills = const [], this.tripsDone = false, this.fillsDone = false, this.loading = false});
  final FeedDocs trips;
  final FeedDocs fills;
  final bool tripsDone;
  final bool fillsDone;
  final bool loading;
  bool get done => tripsDone && fillsDone;
}

class OlderPagesNotifier extends Notifier<OlderPages> {
  @override
  OlderPages build() => const OlderPages();

  Future<void> loadMore() async {
    if (state.loading || state.done) return;
    final repo = ref.read(feedRepositoryProvider);
    final firstTrips = ref.read(_firstTripsProvider).value ?? const [];
    final firstFills = ref.read(_firstFillsProvider).value ?? const [];
    state = OlderPages(trips: state.trips, fills: state.fills, tripsDone: state.tripsDone, fillsDone: state.fillsDone, loading: true);

    Future<FeedDocs> next(String coll, FeedDocs first, FeedDocs older, bool done) async {
      if (done) return const [];
      final all = [...first, ...older];
      if (all.length < feedPageSize) return const [];
      return repo.olderPage(coll, all.last);
    }

    final t = await next('trips', firstTrips, state.trips, state.tripsDone);
    final f = await next('fuelLogs', firstFills, state.fills, state.fillsDone);
    state = OlderPages(
      trips: [...state.trips, ...t],
      fills: [...state.fills, ...f],
      tripsDone: state.tripsDone || t.length < feedPageSize,
      fillsDone: state.fillsDone || f.length < feedPageSize,
    );
  }
}

final olderPagesProvider = NotifierProvider<OlderPagesNotifier, OlderPages>(OlderPagesNotifier.new);

/// This driver's logs that the server hasn't confirmed yet, as the phone has them.
final _myUnsentProvider = StreamProvider<({List<LocalTrip> trips, List<LocalFuelLog> fills, Map<String, List<LocalEvidenceData>> ev})>((ref) {
  final session = ref.watch(sessionProvider).value;
  final db = ref.watch(appDatabaseProvider);
  if (session is! SignedIn) return Stream.value((trips: const [], fills: const [], ev: const {}));
  final uid = session.user.uid;
  return db
      .customSelect('SELECT 1', readsFrom: {db.localTrips, db.localFuelLogs, db.localEvidence})
      .watch()
      .asyncMap((_) async {
    final trips = await (db.select(db.localTrips)
          ..where((t) =>
              t.driverId.equals(uid) &
              (t.startSync.equals(SyncState.synced).not() |
                  (t.status.equals('closed') & t.endSync.equals(SyncState.synced).not()))))
        .get();
    final fills = await (db.select(db.localFuelLogs)
          ..where((f) => f.driverId.equals(uid) & f.sync.equals(SyncState.synced).not()))
        .get();
    final ids = {...trips.map((t) => t.id), ...fills.map((f) => f.id)};
    final ev = <String, List<LocalEvidenceData>>{};
    if (ids.isNotEmpty) {
      final rows = await (db.select(db.localEvidence)
            ..where((e) => e.logId.isIn(ids))
            ..orderBy([(e) => OrderingTerm.asc(e.capturedAtDevice)]))
          .get();
      for (final e in rows) {
        (ev[e.logId] ??= []).add(e);
      }
    }
    return (trips: trips, fills: fills, ev: ev);
  });
});

/// The shared feed: everyone's trips and fills, newest first, with this
/// driver's not-yet-confirmed logs merged in from the phone.
final feedProvider = Provider<AsyncValue<List<FeedEntry>>>((ref) {
  final trips = ref.watch(_firstTripsProvider);
  final fills = ref.watch(_firstFillsProvider);
  final older = ref.watch(olderPagesProvider);
  final unsent = ref.watch(_myUnsentProvider).value;
  if (trips.isLoading && fills.isLoading && unsent == null) return const AsyncLoading();

  final byId = <String, FeedEntry>{};
  for (final d in [...?trips.value, ...older.trips]) {
    byId[d.id] = FeedEntry.fromTripDoc(d);
  }
  for (final d in [...?fills.value, ...older.fills]) {
    byId[d.id] = FeedEntry.fromFillDoc(d);
  }
  if (unsent != null) {
    for (final t in unsent.trips) {
      byId[t.id] = FeedEntry.fromLocalTrip(t, unsent.ev[t.id] ?? const [], server: byId[t.id]);
    }
    for (final f in unsent.fills) {
      byId[f.id] = FeedEntry.fromLocalFill(f, unsent.ev[f.id] ?? const [], server: byId[f.id]);
    }
  }
  final list = byId.values.toList()..sort((a, b) => b.time.compareTo(a.time));
  return AsyncData(list);
});

/// What happened to an edit.
enum EditOutcome { noChanges, savedOnPhone, sent, queued }

class FeedRepository {
  FeedRepository(this._fs, this._db);

  final FirebaseFirestore _fs;
  final AppDatabase _db;

  Query<Map<String, dynamic>> _ordered(String coll) =>
      _fs.collection(coll).orderBy('createdAt', descending: true).limit(feedPageSize);

  Stream<FeedDocs> firstPage(String coll) => _ordered(coll).snapshots(includeMetadataChanges: true).map((s) => s.docs);

  Future<FeedDocs> olderPage(String coll, DocumentSnapshot after) async =>
      (await _ordered(coll).startAfterDocument(after).get()).docs;

  /// Edits a fill's typed fields. If it was already submitted, the change and
  /// the previous values (history) go to Firestore in ONE batch; otherwise it's
  /// just changed on the phone (nothing was submitted yet, so no history).
  Future<EditOutcome> editFill({
    required String id,
    required String uid,
    required int odometer,
    required double liters,
    required double pricePerL,
    required double total,
    required String fuelType,
    required String paidBy,
  }) async {
    final values = <String, Object>{
      'odometer': odometer,
      'liters': liters,
      'pricePerL': pricePerL,
      'total': total,
      'fuelType': fuelType,
      'paidBy': paidBy,
    };
    final local = await (_db.select(_db.localFuelLogs)..where((f) => f.id.equals(id))).getSingleOrNull();
    if (local != null) {
      await (_db.update(_db.localFuelLogs)..where((f) => f.id.equals(id))).write(LocalFuelLogsCompanion(
        odometer: Value(odometer),
        liters: Value(liters),
        pricePerL: Value(pricePerL),
        total: Value(total),
        fuelType: Value(fuelType),
        paidBy: Value(paidBy),
      ));
      if (local.sync == SyncState.local) return EditOutcome.savedOnPhone;
    }

    final ref = _fs.collection('fuelLogs').doc(id);
    final prev = (await ref.get()).data();
    if (prev == null) throw StateError('This fill is not on the server yet. Try again in a moment.');
    if (prev['status'] != 'pending') throw StateError('This fill was already reviewed and is locked.');
    final changed = {for (final e in values.entries) if (prev[e.key] != e.value) e.key: e.value};
    if (changed.isEmpty) return EditOutcome.noChanges;

    return _commitEdit(ref, uid, changed, previous: {
      for (final k in values.keys) k: prev[k],
    });
  }

  /// Edits a trip's readings (start always; end only once it has ended).
  Future<EditOutcome> editTrip({required String id, required String uid, required int startOdo, int? endOdo}) async {
    final local = await (_db.select(_db.localTrips)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      await (_db.update(_db.localTrips)..where((t) => t.id.equals(id))).write(LocalTripsCompanion(
        startOdo: Value(startOdo),
        endOdo: local.status == 'closed' && endOdo != null ? Value(endOdo) : const Value.absent(),
      ));
    }
    // Which parts were already submitted? Unsubmitted parts change on the phone
    // only; the sync engine sends the new values later.
    final startSubmitted = local == null || local.startSync != SyncState.local;
    final endSubmitted = local == null || (local.status == 'closed' && local.endSync != SyncState.local);
    if (!startSubmitted) return EditOutcome.savedOnPhone;

    final ref = _fs.collection('trips').doc(id);
    final prev = (await ref.get()).data();
    if (prev == null) throw StateError('This trip is not on the server yet. Try again in a moment.');
    if (prev['reviewed'] == true) throw StateError('This trip was already reviewed and is locked.');
    final changed = <String, Object>{
      if (prev['startOdo'] != startOdo) 'startOdo': startOdo,
      if (endSubmitted && prev['status'] == 'closed' && endOdo != null && prev['endOdo'] != endOdo) 'endOdo': endOdo,
    };
    if (changed.isEmpty) return local != null ? EditOutcome.savedOnPhone : EditOutcome.noChanges;

    return _commitEdit(ref, uid, changed, previous: {'startOdo': prev['startOdo'], 'endOdo': prev['endOdo']});
  }

  /// One batch: the changed fields + "edited" stamp, and the history entry with
  /// the values before the change. Firestore queues it if offline.
  Future<EditOutcome> _commitEdit(
    DocumentReference<Map<String, dynamic>> ref,
    String uid,
    Map<String, Object> changed, {
    required Map<String, Object?> previous,
  }) async {
    final editId = newId();
    final batch = _fs.batch()
      ..update(ref, {
        ...changed,
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
        'lastEditId': editId,
      })
      ..set(ref.collection('edits').doc(editId), {
        'previous': previous,
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': uid,
      });
    // Online: confirmed in a moment. Offline: stays queued and is sent later.
    try {
      await batch.commit().timeout(const Duration(seconds: 6));
      return EditOutcome.sent;
    } on TimeoutException {
      return EditOutcome.queued;
    }
  }
}
