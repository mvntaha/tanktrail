import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/sync/sync_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/ids.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../evidence/data/ocr_service.dart';
import '../../evidence/domain/captured_media.dart';
import '../../evidence/presentation/camera_capture_screen.dart';
import '../../evidence/presentation/evidence_slot.dart';
import '../../evidence/presentation/location_gate.dart';
import '../data/trip_repository.dart';
import '../domain/trip.dart';

/// Start a trip (no [endTripId]) or end the given trip: odometer photo (required,
/// with GPS) + typed reading. Saved on the phone only for now.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.endTripId});

  final String? endTripId;

  bool get isEnd => endTripId != null;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  late final String _tripId = widget.endTripId ?? newId();
  final _odo = TextEditingController();
  CapturedMedia? _photo;
  // OCR of the photo, running in the background while the driver types.
  Future<String?>? _ocr;
  bool _saving = false;

  @override
  void dispose() {
    _odo.dispose();
    super.dispose();
  }

  int? get _reading => int.tryParse(_odo.text);

  Future<void> _takePhoto() async {
    if (!await ensureLocation(context, ref)) return;
    if (!mounted) return;
    final media = await Navigator.of(context).push<CapturedMedia>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CameraCaptureScreen(
          logId: _tripId,
          type: 'odometer',
          hint: 'Show the ODO (total km), not TRIP',
        ),
      ),
    );
    if (media == null || !mounted) return;
    final old = _photo;
    setState(() => _photo = media);
    _ocr = ref.read(ocrServiceProvider).readWithin(media.filePath, CameraCaptureScreen.odometerGuide);
    // A replaced photo was never saved to a log, so its file can go.
    if (old != null) File(old.filePath).delete().ignore();
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Fix it')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save anyway')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save(Trip? trip) async {
    final reading = _reading;
    final taken = _photo;
    final session = ref.read(sessionProvider).value;
    if (reading == null || taken == null || session is! SignedIn) return;

    // Soft checks only: a typo is fixable later, a blocked log loses evidence.
    if (trip == null) {
      final last = ref.read(lastOdometerProvider).value;
      if (last != null && reading < last &&
          !await _confirm('Lower than before?', 'The last reading on this phone was ${formatKm(last)}. '
              'You entered ${formatKm(reading)}.')) {
        return;
      }
    } else {
      if (reading < trip.startOdo &&
          !await _confirm('Lower than the start?', 'This trip started at ${formatKm(trip.startOdo)}. '
              'You entered ${formatKm(reading)}.')) {
        return;
      }
      if (reading - trip.startOdo > 1000 &&
          !await _confirm('Very long trip?', 'That is ${formatKm(reading - trip.startOdo)}. Is the reading right?')) {
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final photo = taken.withOcrText(await _ocr);
      final repo = ref.read(tripRepositoryProvider);
      if (trip == null) {
        await repo.startTrip(tripId: _tripId, driver: session.user, startOdo: reading, photo: photo);
      } else {
        await repo.endTrip(tripId: trip.id, endOdo: reading, photo: photo);
      }
      HapticFeedback.mediumImpact();
      // Upload right away if there is internet; otherwise it waits.
      ref.read(syncServiceProvider).kick().ignore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trip == null ? 'Trip started' : 'Trip ended')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final trip = widget.isEnd ? ref.watch(tripByIdProvider(widget.endTripId!)).value : null;
    final last = ref.watch(lastOdometerProvider).value;
    final canSave = _photo != null && _reading != null && !_saving && (!widget.isEnd || trip != null);

    return PopScope(
      // Ask before throwing away a photo that was already taken.
      canPop: _photo == null || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard?'),
            content: const Text('The photo you took will not be saved.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          File(_photo!.filePath).delete().ignore();
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isEnd ? 'End trip' : 'Start trip')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (trip != null) ...[
              _InfoRow(
                icon: Icons.flag_rounded,
                text: 'Started ${formatWhen(trip.startedAt)} at ${formatKm(trip.startOdo)}',
              ),
              const SizedBox(height: 16),
            ],
            Text('1. Odometer photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.foreground)),
            const SizedBox(height: 10),
            EvidenceSlot(
              label: 'Take odometer photo',
              icon: Icons.photo_camera_rounded,
              media: _photo,
              onCapture: _saving ? null : _takePhoto,
              height: 160,
            ),
            const SizedBox(height: 24),
            Text('2. Odometer reading', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.foreground)),
            const SizedBox(height: 10),
            TextField(
              controller: _odo,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 1),
              decoration: const InputDecoration(hintText: '0', suffixText: 'km'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (!widget.isEnd && last != null)
              Text('Last reading on this phone: ${formatKm(last)}', style: TextStyle(color: t.mutedForeground, fontSize: 14)),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canSave ? () => _save(trip) : null,
              child: _saving
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: t.primaryForeground),
                    )
                  : Text(widget.isEnd ? 'End trip' : 'Start trip'),
            ),
            const SizedBox(height: 12),
            Text(
              'Saved on this phone first, then uploaded when there is internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.mutedForeground, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.muted, borderRadius: BorderRadius.circular(t.radiusSm)),
      child: Row(
        children: [
          Icon(icon, color: t.mutedForeground),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: t.foreground))),
        ],
      ),
    );
  }
}
