import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart' show SyncState;
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../fuel/domain/fuel_log.dart';
import '../domain/feed_entry.dart';
import 'media_viewer_screen.dart';

/// 4902 -> "Rs 4,902", 4902.5 -> "Rs 4,902.50"
String _rupees(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = formatThousands(int.parse(parts[0]));
  return parts[1] == '00' ? 'Rs $whole' : 'Rs $whole.${parts[1]}';
}

/// One log in the shared feed, like a message in a group chat.
class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.entry, required this.isMine, this.onEdit});

  final FeedEntry entry;
  final bool isMine;

  /// Shown only for the driver's own logs that are still editable.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = entry;
    final initial = e.driverName.isEmpty ? '?' : e.driverName.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: isMine ? t.ring.withValues(alpha: 0.35) : t.border),
        boxShadow: t.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: t.accent,
                child: Text(initial, style: TextStyle(color: t.accentForeground, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isMine ? '${e.driverName} (you)' : e.driverName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.cardForeground)),
                    Text(e.isTrip ? 'Trip' : 'Fuel fill', style: TextStyle(fontSize: 13, color: t.mutedForeground)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatWhen(e.time), style: TextStyle(fontSize: 13, color: t.mutedForeground)),
                  if (e.edited)
                    Text('edited', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: t.mutedForeground)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (e.isTrip) _TripBody(entry: e) else _FillBody(entry: e),
          if (e.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: e.media.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MediaViewerScreen(media: e.media, initial: i),
                  )),
                  child: FeedThumb(media: e.media[i]),
                ),
              ),
            ),
          ],
          if (isMine) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SyncBadge(logId: e.id),
                const Spacer(),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          ] else if (e.sending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('sending...', style: TextStyle(fontSize: 12, color: t.mutedForeground)),
            ),
        ],
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.entry});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = entry;
    final km = e.distanceKm;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Text(
          e.tripOpen ? 'In progress' : (km == null ? 'Trip' : formatKm(km)),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.cardForeground),
        ),
        Text(
          e.tripOpen || e.endOdo == null
              ? 'from ${formatKm(e.startOdo ?? 0)}'
              : '${formatKm(e.startOdo ?? 0)} → ${formatKm(e.endOdo!)}',
          style: TextStyle(fontSize: 15, color: t.mutedForeground),
        ),
        if (e.reviewed) const _Chip(label: 'Reviewed', tone: _Tone.good),
      ],
    );
  }
}

class _FillBody extends StatelessWidget {
  const _FillBody({required this.entry});

  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = entry;
    final (label, tone) = switch (e.status) {
      'approved' => ('Approved', _Tone.good),
      'rejected' => ('Rejected', _Tone.bad),
      _ => ('Pending review', _Tone.neutral),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(_rupees(e.total ?? 0), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.cardForeground)),
            Text('${(e.liters ?? 0).toStringAsFixed(2)} L × Rs ${(e.pricePerL ?? 0).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, color: t.mutedForeground)),
            _Chip(label: label, tone: tone),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatKm(e.odometer ?? 0)}  ·  ${fuelTypeLabels[e.fuelType] ?? e.fuelType ?? ''}  ·  '
          '${e.paidBy == 'own' ? 'Own money' : 'Company cash'}',
          style: TextStyle(fontSize: 14, color: t.mutedForeground),
        ),
        if (e.status == 'rejected' && (e.reviewNote ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Reason: ${e.reviewNote}', style: TextStyle(fontSize: 14, color: t.destructive)),
          ),
      ],
    );
  }
}

enum _Tone { good, bad, neutral }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (tone) {
      _Tone.good => (t.accent, t.accentForeground),
      _Tone.bad => (t.destructive, t.destructiveForeground),
      _Tone.neutral => (t.muted, t.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(t.radiusSm)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Where the driver's own log is: waiting, uploading n/m, sending, sent, or not accepted.
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key, required this.logId});

  final String logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final sync = ref.watch(logSyncProvider).value?[logId];
    final label = sync?.label ?? 'Sent';
    final (bg, fg) = switch (sync?.state) {
      SyncState.rejected => (t.destructive, t.destructiveForeground),
      SyncState.synced || null => (t.accent, t.accentForeground),
      _ => (t.muted, t.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(t.radiusSm)),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
