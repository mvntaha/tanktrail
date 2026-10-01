import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../feed/presentation/media_viewer_screen.dart';
import '../../fuel/domain/fuel_log.dart';
import '../data/admin_repository.dart';
import '../domain/admin_log.dart';
import '../domain/flags.dart';
import 'admin_map.dart';

/// Everything about one log, for review.
class AdminLogScreen extends ConsumerStatefulWidget {
  const AdminLogScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends ConsumerState<AdminLogScreen> {
  bool _busy = false;

  /// Runs a review action. Offline it is queued by Firestore and sent later.
  Future<void> _act(Future<void> Function(AdminRepository r) action, String done) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(adminRepositoryProvider)).timeout(const Duration(seconds: 6));
      _snack(done);
    } on TimeoutException {
      _snack('$done (will sync when online)');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      ref.invalidate(adminDataProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _askText(String title, String hint, {String initial = '', bool required = true}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, maxLines: 3, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (required && c.text.trim().isEmpty) return;
              Navigator.pop(context, c.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = ref.watch(adminDataProvider).value;
    final log = data?.byId(widget.id);
    if (data == null || log == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final flags = data.flags[log.id]!;
    final l = log;

    final pins = <MapPin>[
      if (l.startLoc != null) MapPin(LatLng(l.startLoc!.lat, l.startLoc!.lng), 'Start', colorIndex: 1),
      if (l.endLoc != null) MapPin(LatLng(l.endLoc!.lat, l.endLoc!.lng), 'End', colorIndex: 4),
      if (l.loc != null) MapPin(LatLng(l.loc!.lat, l.loc!.lng), 'Fill', colorIndex: 0),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.isTrip ? 'Trip' : 'Fuel fill')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text('${l.driverName} · ${formatWhen(l.deviceTime)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
          Text(
            'Recorded on phone ${formatWhen(l.deviceTime)}; reached server '
            '${l.createdAt == null ? 'not yet' : formatWhen(l.createdAt!)}',
            style: TextStyle(fontSize: 13, color: t.mutedForeground),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Flags',
            child: flags.isEmpty
                ? Text('No flags.', style: TextStyle(color: t.mutedForeground))
                : Column(children: [for (final f in flags) _FlagRow(flag: f)]),
          ),
          _Section(title: 'Values', child: _Values(log: l, places: data.places)),
          if (pins.isNotEmpty)
            _Section(
              title: 'Map',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminMap(pins: pins, places: data.places),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Name this place'),
                      onPressed: () {
                        final at = l.loc ?? l.startLoc ?? l.endLoc!;
                        context.push(Routes.adminPlaceNew, extra: Place(id: '', name: '', lat: at.lat, lng: at.lng));
                      },
                    ),
                  ),
                ],
              ),
            ),
          _Section(title: 'Evidence', child: _Evidence(log: l)),
          if (l.edited) _Section(title: 'Edit history', child: _History(log: l)),
          _Section(title: 'Review', child: _actions(l, flags)),
        ],
      ),
    );
  }

  Widget _actions(AdminLog l, List<Flag> flags) {
    final t = context.tokens;
    if (l.isTrip) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((l.adminNote ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Note: ${l.adminNote}', style: TextStyle(color: t.foreground)),
            ),
          if (!l.reviewed)
            FilledButton(
              onPressed: _busy || l.tripOpen ? null : () => _act((r) => r.setTripReviewed(l.id, true), 'Marked reviewed'),
              child: Text(l.tripOpen ? 'Trip still open' : 'Mark reviewed (locks it)'),
            )
          else
            OutlinedButton(
              onPressed: _busy ? null : () => _act((r) => r.setTripReviewed(l.id, false), 'Reopened for the driver'),
              child: const Text('Reopen (unlock for driver)'),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final note = await _askText('Note', 'Visible to admins only', initial: l.adminNote ?? '', required: false);
                    if (note != null) await _act((r) => r.setTripReviewed(l.id, l.reviewed, note: note), 'Note saved');
                  },
            child: const Text('Add / edit note'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (l.status == 'rejected' && (l.reviewNote ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Rejected: ${l.reviewNote}', style: TextStyle(color: t.destructive)),
          ),
        if (l.status == 'pending') ...[
          FilledButton(
            onPressed: _busy ? null : () => _act((r) => r.approveFill(l.id), 'Approved'),
            child: const Text('Approve'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final reason = await _askText('Reject fill', 'Reason (the driver sees it)');
                    if (reason != null) await _act((r) => r.rejectFill(l.id, reason), 'Rejected');
                  },
            child: const Text('Reject with reason'),
          ),
          if (flags.isNotEmpty) ...[
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: l.flagsReviewed,
              title: const Text('Flags checked'),
              onChanged: _busy ? null : (v) => _act((r) => r.setFillFlagsReviewed(l.id, v ?? false), 'Saved'),
            ),
          ],
        ] else
          OutlinedButton(
            onPressed: _busy ? null : () => _act((r) => r.reopenFill(l.id), 'Reopened as pending'),
            child: const Text('Reopen (back to pending)'),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.foreground)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag});
  final Flag flag;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (icon, color) = switch (flag.level) {
      FlagLevel.high => (Icons.error_rounded, t.destructive),
      FlagLevel.medium => (Icons.warning_amber_rounded, t.chart[3]),
      FlagLevel.low => (Icons.info_outline_rounded, t.mutedForeground),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(flag.message, style: TextStyle(fontSize: 14, height: 1.35, color: t.foreground))),
        ],
      ),
    );
  }
}

class _Values extends StatelessWidget {
  const _Values({required this.log, required this.places});
  final AdminLog log;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = log;
    String where(GeoPoint2? g) {
      if (g == null) return '–';
      final name = placeName(g, places);
      return '${name ?? 'Unnamed place'} (±${g.acc.round()} m${g.mock ? ', MOCK' : ''})';
    }

    final rows = <(String, String)>[
      if (l.isTrip) ...[
        ('Start', '${formatKm(l.startOdo ?? 0)} · ${where(l.startLoc)}'),
        if (!l.tripOpen) ('End', '${formatKm(l.endOdo ?? 0)} · ${where(l.endLoc)}'),
        if (!l.tripOpen) ('Distance', formatKm((l.endOdo ?? 0) - (l.startOdo ?? 0))),
      ] else ...[
        ('Odometer', formatKm(l.odometer ?? 0)),
        ('Litres', '${(l.liters ?? 0).toStringAsFixed(2)} L'),
        ('Price', 'Rs ${(l.pricePerL ?? 0).toStringAsFixed(2)} / L'),
        ('Total', 'Rs ${(l.total ?? 0).toStringAsFixed(2)}'),
        ('Fuel', fuelTypeLabels[l.fuelType] ?? '${l.fuelType}'),
        ('Paid by', paidByLabels[l.paidBy] ?? '${l.paidBy}'),
        ('Status', '${l.status}'),
        ('Where', where(l.loc)),
      ],
    ];
    return Column(
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 90, child: Text(k, style: TextStyle(color: t.mutedForeground, fontSize: 14))),
                Expanded(child: Text(v, style: TextStyle(color: t.foreground, fontSize: 15))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Evidence extends StatelessWidget {
  const _Evidence({required this.log});
  final AdminLog log;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = log;
    // Public items and private details share the file's ID (end of publicId/url).
    String? ocrFor(int i) {
      final url = l.media[i].url ?? '';
      for (final p in l.privateMedia) {
        if (p.mediaId.isNotEmpty && url.contains(p.mediaId)) return p.ocrText;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < l.media.length; i++)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MediaViewerScreen(media: l.media, initial: i),
                )),
                child: FeedThumb(media: l.media[i], size: 96),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < l.media.length; i++)
          if (!l.media[i].isVideo)
            Text(
              '${l.media[i].type == 'pump' ? 'Pump' : 'Odometer'} photo ${i + 1}: OCR read '
              '${ocrFor(i) == null ? 'nothing' : '"${ocrFor(i)!.replaceAll('\n', ' / ')}"'}',
              style: TextStyle(fontSize: 13, color: t.mutedForeground),
            ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.log});
  final AdminLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = log;
    final history = ref.watch(editHistoryProvider((isTrip: l.isTrip, id: l.id)));
    final current = <String, Object?>{
      if (l.isTrip) ...{'startOdo': l.startOdo, 'endOdo': l.endOdo},
      if (!l.isTrip) ...{
        'odometer': l.odometer,
        'liters': l.liters,
        'pricePerL': l.pricePerL,
        'total': l.total,
        'fuelType': l.fuelType,
        'paidBy': l.paidBy,
      },
    };
    return switch (history) {
      AsyncData(value: final edits) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < edits.length; i++)
              Builder(builder: (context) {
                final prev = (edits[i]['previous'] as Map?)?.cast<String, Object?>() ?? const {};
                // What it became: the next edit's "previous", or the current values.
                final next = i + 1 < edits.length
                    ? ((edits[i + 1]['previous'] as Map?)?.cast<String, Object?>() ?? const {})
                    : current;
                final when = (edits[i]['editedAt'] as Timestamp?)?.toDate();
                final changes = [
                  for (final k in prev.keys)
                    if (prev[k] != next[k]) '$k: ${prev[k]} → ${next[k]}',
                ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${when == null ? 'pending' : formatWhen(when)}: ${changes.isEmpty ? 'no value change' : changes.join(', ')}',
                    style: TextStyle(fontSize: 14, color: t.foreground),
                  ),
                );
              }),
          ],
        ),
      AsyncError(:final error) => Text('Could not load history: $error', style: TextStyle(color: t.destructive)),
      _ => const LinearProgressIndicator(),
    };
  }
}
