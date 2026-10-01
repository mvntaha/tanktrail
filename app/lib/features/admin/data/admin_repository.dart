import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ids.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/admin_log.dart';
import '../domain/flags.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(firestoreProvider)));

/// How many days the admin screens look back.
final adminWindowDaysProvider = NotifierProvider<_WindowDays, int>(_WindowDays.new);

class _WindowDays extends Notifier<int> {
  @override
  int build() => 7;
  void set(int days) => state = days;
}

/// Everything the admin screens need for the current window, flags included.
class AdminData {
  const AdminData({required this.logs, required this.vehicle, required this.places, required this.flags, required this.stats});
  final List<AdminLog> logs;
  final Vehicle vehicle;
  final List<Place> places;
  final Map<String, List<Flag>> flags;
  final WindowStats stats;

  AdminLog? byId(String id) => logs.where((l) => l.id == id).firstOrNull;
}

/// One-off reads (no live listeners) to stay well inside the free quota.
/// Pull to refresh re-reads; the offline cache answers when there's no internet.
final adminDataProvider = FutureProvider<AdminData>((ref) async {
  // Per sign-in: nothing from a previous login is kept or shown.
  if (ref.watch(currentUidProvider) == null) throw StateError('Signed out');
  final days = ref.watch(adminWindowDaysProvider);
  final repo = ref.watch(adminRepositoryProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  final (logs, vehicle, places) = await (repo.logsSince(since), repo.vehicle(), repo.places()).wait;
  return AdminData(
    logs: logs,
    vehicle: vehicle,
    places: places,
    flags: computeFlags(logs, vehicle),
    stats: computeStats(logs),
  );
});

/// A log's edit history (previous values), newest last. Admin only.
final editHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, ({bool isTrip, String id})>((ref, key) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).edits(key.isTrip, key.id);
});

class AdminRepository {
  AdminRepository(this._fs);

  final FirebaseFirestore _fs;

  Future<List<AdminLog>> logsSince(DateTime since) async {
    Future<List<AdminLog>> load(String coll, AdminLog Function(String, Map<String, dynamic>, Map<String, dynamic>?) make) async {
      final docs = (await _fs
              .collection(coll)
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
              .orderBy('createdAt', descending: true)
              .get())
          .docs;
      // private/geo is admin-only; one read per log, in parallel.
      final geos = await Future.wait(docs.map((d) => d.reference.collection('private').doc('geo').get()));
      return [for (var i = 0; i < docs.length; i++) make(docs[i].id, docs[i].data(), geos[i].data())];
    }

    final (trips, fills) = await (load('trips', AdminLog.fromTrip), load('fuelLogs', AdminLog.fromFill)).wait;
    return [...trips, ...fills]..sort((a, b) => (b.createdAt ?? b.deviceTime).compareTo(a.createdAt ?? a.deviceTime));
  }

  Future<Vehicle> vehicle() async => Vehicle.fromMap((await _fs.doc('vehicle/main').get()).data());

  Future<List<Place>> places() async =>
      (await _fs.collection('places').get()).docs.map((d) => Place.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Future<List<Map<String, dynamic>>> edits(bool isTrip, String id) async {
    final snap = await _fs.collection(isTrip ? 'trips' : 'fuelLogs').doc(id).collection('edits').orderBy('editedAt').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ---------- review actions (exactly the fields the rules allow) ----------

  Future<void> approveFill(String id) => _fs.doc('fuelLogs/$id').update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  Future<void> rejectFill(String id, String reason) {
    if (reason.trim().isEmpty) throw ArgumentError('A reason is required');
    return _fs.doc('fuelLogs/$id').update({
      'status': 'rejected',
      'reviewNote': reason.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Back to pending: the driver can edit it again.
  Future<void> reopenFill(String id) => _fs.doc('fuelLogs/$id').update({
        'status': 'pending',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setFillFlagsReviewed(String id, bool value) => _fs.doc('fuelLogs/$id').update({'flagsReviewed': value});

  /// Trips have no separate "flags reviewed": marking reviewed covers both, and locks it.
  Future<void> setTripReviewed(String id, bool reviewed, {String? note}) => _fs.doc('trips/$id').update({
        'reviewed': reviewed,
        'reviewedAt': FieldValue.serverTimestamp(),
        if (note != null) 'adminNote': note.trim(),
      });

  Future<void> saveVehicle(Vehicle v) => _fs.doc('vehicle/main').set(v.toMap());

  /// Places can be added or changed, never deleted (rules deny deletes).
  Future<void> savePlace(Place p) => _fs.doc('places/${p.id.isEmpty ? newId() : p.id}').set(p.toMap());
}
