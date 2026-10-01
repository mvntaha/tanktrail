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
import '../../evidence/presentation/video_capture_screen.dart';
import '../../trips/data/trip_repository.dart';
import '../data/fuel_repository.dart';
import '../domain/fuel_log.dart';

/// Log a fuel fill: 3 in-app captures + the pump's numbers. Saved on the
/// phone only for now (uploading arrives in Milestone 5).
class FuelFormScreen extends ConsumerStatefulWidget {
  const FuelFormScreen({super.key});

  @override
  ConsumerState<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends ConsumerState<FuelFormScreen> {
  final String _id = newId();
  final _odo = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _total = TextEditingController();

  CapturedMedia? _odoPhoto;
  CapturedMedia? _video;
  CapturedMedia? _pumpPhoto;
  String _fuelType = 'petrol';
  String? _paidBy; // no default: who paid must be a deliberate choice
  bool _totalTypedByHand = false;
  // OCR runs in the background after each photo, while the driver types.
  final _ocr = <String, Future<String?>>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_odo, _liters, _price, _total]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final v = double.tryParse(c.text);
    return v == null || v <= 0 ? null : v;
  }

  List<CapturedMedia> get _captured => [_odoPhoto, _video, _pumpPhoto].whereType<CapturedMedia>().toList();

  /// Fills Total from liters x price, unless the driver typed Total themselves.
  void _autoTotal() {
    if (_totalTypedByHand) return;
    final l = _num(_liters);
    final p = _num(_price);
    _total.text = (l != null && p != null) ? suggestTotal(l, p).toStringAsFixed(2) : '';
  }

  Future<CapturedMedia?> _capture(Widget screen) async {
    if (!await ensureLocation(context, ref)) return null;
    if (!mounted) return null;
    return Navigator.of(context).push<CapturedMedia>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen),
    );
  }

  /// Replaces a slot; a replaced capture was never saved, so its file can go.
  void _set(CapturedMedia? old, CapturedMedia media, void Function(CapturedMedia) assign) {
    setState(() => assign(media));
    if (old != null) File(old.filePath).delete().ignore();
  }

  Future<void> _takeOdo() async {
    final m = await _capture(CameraCaptureScreen(
      logId: _id,
      type: 'odometer',
      hint: 'Show the ODO (total km), not TRIP',
    ));
    if (m != null && mounted) {
      _set(_odoPhoto, m, (v) => _odoPhoto = v);
      _ocr[m.id] = ref.read(ocrServiceProvider).readWithin(m.filePath, CameraCaptureScreen.odometerGuide);
    }
  }

  Future<void> _takeVideo() async {
    final m = await _capture(VideoCaptureScreen(logId: _id));
    if (m != null && mounted) _set(_video, m, (v) => _video = v);
  }

  Future<void> _takePump() async {
    final m = await _capture(CameraCaptureScreen(
      logId: _id,
      type: 'pump',
      hint: 'Pump display: rupees, litres and price all visible',
      guide: CameraCaptureScreen.pumpGuide,
    ));
    if (m != null && mounted) {
      _set(_pumpPhoto, m, (v) => _pumpPhoto = v);
      _ocr[m.id] = ref.read(ocrServiceProvider).readWithin(m.filePath, CameraCaptureScreen.pumpGuide);
    }
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

  bool get _complete =>
      _odoPhoto != null &&
      _video != null &&
      _pumpPhoto != null &&
      int.tryParse(_odo.text) != null &&
      _num(_liters) != null &&
      _num(_price) != null &&
      _num(_total) != null &&
      _paidBy != null;

  Future<void> _save() async {
    final session = ref.read(sessionProvider).value;
    if (!_complete || session is! SignedIn) return;
    final odo = int.parse(_odo.text);
    final liters = _num(_liters)!;
    final price = _num(_price)!;
    final total = _num(_total)!;

    // Soft checks: warn, never block.
    final last = ref.read(lastOdometerProvider).value;
    if (last != null && odo < last &&
        !await _confirm('Lower than before?',
            'The last reading on this phone was ${formatKm(last)}. You entered ${formatKm(odo)}.')) {
      return;
    }
    if (!amountsConsistent(liters, price, total) &&
        !await _confirm('Amounts don\'t add up',
            '$liters L x Rs $price = Rs ${suggestTotal(liters, price).toStringAsFixed(2)}, '
            'but Total is Rs ${total.toStringAsFixed(2)}.')) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(fuelRepositoryProvider).saveFill(
            id: _id,
            driver: session.user,
            odometer: odo,
            liters: liters,
            pricePerL: price,
            total: total,
            fuelType: _fuelType,
            paidBy: _paidBy!,
            // Usually finished long ago; at most a few seconds' wait, never a block.
            odometerPhoto: _odoPhoto!.withOcrText(await _ocr[_odoPhoto!.id]),
            pumpPhoto: _pumpPhoto!.withOcrText(await _ocr[_pumpPhoto!.id]),
            pumpVideo: _video!,
          );
      HapticFeedback.mediumImpact();
      // Upload right away if there is internet; otherwise it waits.
      ref.read(syncServiceProvider).kick().ignore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fuel fill saved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Widget _heading(String text) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.foreground)),
    );
  }

  Widget _numberField(TextEditingController c, String label, {String? prefix, String? suffix, bool decimals = true}) {
    return TextField(
      controller: c,
      enabled: !_saving,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [
        decimals
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}(\.\d{0,2})?'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix),
      onChanged: (_) => setState(() {
        if (c == _total) _totalTypedByHand = _total.text.isNotEmpty;
        if (c == _liters || c == _price) _autoTotal();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final last = ref.watch(lastOdometerProvider).value;

    return PopScope(
      canPop: _captured.isEmpty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard this fill?'),
            content: const Text('The photos and video you took will not be saved.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          for (final m in _captured) {
            File(m.filePath).delete().ignore();
          }
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Log fuel')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            _heading('1. Odometer photo'),
            EvidenceSlot(
              label: 'Take odometer photo',
              icon: Icons.speed_rounded,
              media: _odoPhoto,
              onCapture: _saving ? null : _takeOdo,
            ),
            _heading('2. Pump video (while fueling, max 60 s)'),
            EvidenceSlot(
              label: 'Record pump video',
              icon: Icons.videocam_rounded,
              media: _video,
              onCapture: _saving ? null : _takeVideo,
            ),
            _heading('3. Pump display photo (after fueling)'),
            EvidenceSlot(
              label: 'Take pump photo',
              icon: Icons.local_gas_station_rounded,
              media: _pumpPhoto,
              onCapture: _saving ? null : _takePump,
            ),
            _heading('4. Numbers'),
            _numberField(_odo, 'Odometer', suffix: 'km', decimals: false),
            if (last != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Last reading on this phone: ${formatKm(last)}',
                    style: TextStyle(color: t.mutedForeground, fontSize: 14)),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _numberField(_liters, 'Litres', suffix: 'L')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_price, 'Price per litre', prefix: 'Rs ')),
              ],
            ),
            const SizedBox(height: 14),
            _numberField(_total, 'Total paid', prefix: 'Rs '),
            if (!_totalTypedByHand && _total.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Calculated. Change it if the pump shows a different total.',
                    style: TextStyle(color: t.mutedForeground, fontSize: 13)),
              ),
            _heading('5. Fuel type'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final type in fuelTypes)
                  ChoiceChip(
                    label: Text(fuelTypeLabels[type]!, style: const TextStyle(fontSize: 16)),
                    selected: _fuelType == type,
                    onSelected: _saving ? null : (_) => setState(() => _fuelType = type),
                  ),
              ],
            ),
            _heading('6. Who paid?'),
            Row(
              children: [
                for (final entry in paidByLabels.entries) ...[
                  Expanded(
                    child: _PaidByButton(
                      label: entry.value,
                      selected: _paidBy == entry.key,
                      onTap: _saving ? null : () => setState(() => _paidBy = entry.key),
                    ),
                  ),
                  if (entry.key != paidByLabels.keys.last) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _complete && !_saving ? _save : null,
              child: _saving
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: t.primaryForeground),
                    )
                  : const Text('Save fill'),
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

class _PaidByButton extends StatelessWidget {
  const _PaidByButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radius);
    return Material(
      color: selected ? t.primary : t.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? t.primary : t.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? t.primaryForeground : t.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
