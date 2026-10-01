import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/sync/sync_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../fuel/domain/fuel_log.dart';
import '../../fuel/presentation/paid_by_button.dart';
import '../data/feed_repository.dart';
import '../domain/feed_entry.dart';

/// Fix the typed values of one of your own logs. Photos, video, location and
/// times can never be changed. Every change after submission is recorded in
/// the log's history (the admin sees old and new values) and marks it "edited".
class EditLogScreen extends ConsumerStatefulWidget {
  const EditLogScreen({super.key, required this.entry});

  final FeedEntry entry;

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  late final FeedEntry e = widget.entry;
  late final _startOdo = TextEditingController(text: '${e.startOdo ?? ''}');
  late final _endOdo = TextEditingController(text: '${e.endOdo ?? ''}');
  late final _odo = TextEditingController(text: '${e.odometer ?? ''}');
  late final _liters = TextEditingController(text: e.liters?.toStringAsFixed(2) ?? '');
  late final _price = TextEditingController(text: e.pricePerL?.toStringAsFixed(2) ?? '');
  late final _total = TextEditingController(text: e.total?.toStringAsFixed(2) ?? '');
  late String _fuelType = e.fuelType ?? 'petrol';
  late String _paidBy = e.paidBy ?? 'company_cash';
  bool _saving = false;

  bool get _hasEnd => e.isTrip && !e.tripOpen;

  @override
  void dispose() {
    for (final c in [_startOdo, _endOdo, _odo, _liters, _price, _total]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final v = double.tryParse(c.text);
    return v == null || v <= 0 ? null : v;
  }

  bool get _valid => e.isTrip
      ? int.tryParse(_startOdo.text) != null && (!_hasEnd || int.tryParse(_endOdo.text) != null)
      : int.tryParse(_odo.text) != null && _num(_liters) != null && _num(_price) != null && _num(_total) != null;

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

  Future<void> _save() async {
    final session = ref.read(sessionProvider).value;
    if (!_valid || session is! SignedIn) return;
    final repo = ref.read(feedRepositoryProvider);

    setState(() => _saving = true);
    try {
      final EditOutcome outcome;
      if (e.isTrip) {
        final start = int.parse(_startOdo.text);
        final end = _hasEnd ? int.parse(_endOdo.text) : null;
        if (end != null && end < start &&
            !await _confirm('End lower than start?', 'Start ${formatKm(start)}, end ${formatKm(end)}.')) {
          setState(() => _saving = false);
          return;
        }
        outcome = await repo.editTrip(id: e.id, uid: session.user.uid, startOdo: start, endOdo: end);
      } else {
        final liters = _num(_liters)!, price = _num(_price)!, total = _num(_total)!;
        if (!amountsConsistent(liters, price, total) &&
            !await _confirm('Amounts don\'t add up',
                '$liters L x Rs $price = Rs ${suggestTotal(liters, price).toStringAsFixed(2)}, but Total is Rs $total.')) {
          setState(() => _saving = false);
          return;
        }
        outcome = await repo.editFill(
          id: e.id,
          uid: session.user.uid,
          odometer: int.parse(_odo.text),
          liters: liters,
          pricePerL: price,
          total: total,
          fuelType: _fuelType,
          paidBy: _paidBy,
        );
      }
      // Local changes to unsent parts go out with the next sync.
      ref.read(syncServiceProvider).kick().ignore();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final msg = switch (outcome) {
        EditOutcome.noChanges => 'Nothing was changed.',
        EditOutcome.savedOnPhone => 'Saved. It goes out with the log.',
        EditOutcome.sent => 'Saved and marked as edited.',
        EditOutcome.queued => 'Saved. It will be sent when you are online.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      context.pop();
    } catch (err) {
      if (!mounted) return;
      setState(() => _saving = false);
      final text = err is StateError ? err.message : 'Could not save: $err';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Widget _field(TextEditingController c, String label, {String? prefix, String? suffix, bool decimals = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
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
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(e.isTrip ? 'Edit trip' : 'Edit fuel fill')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: t.muted, borderRadius: BorderRadius.circular(t.radiusSm)),
            child: Text(
              'Only typed values can be fixed. Photos, video, location and times stay as recorded. '
              'If the log was already sent, it is marked "edited" and the admin sees the old values.',
              style: TextStyle(fontSize: 14, height: 1.4, color: t.mutedForeground),
            ),
          ),
          const SizedBox(height: 20),
          if (e.isTrip) ...[
            _field(_startOdo, 'Start odometer', suffix: 'km'),
            if (_hasEnd) _field(_endOdo, 'End odometer', suffix: 'km'),
          ] else ...[
            _field(_odo, 'Odometer', suffix: 'km'),
            Row(
              children: [
                Expanded(child: _field(_liters, 'Litres', suffix: 'L', decimals: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_price, 'Price per litre', prefix: 'Rs ', decimals: true)),
              ],
            ),
            _field(_total, 'Total paid', prefix: 'Rs ', decimals: true),
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
            const SizedBox(height: 16),
            Row(
              children: [
                for (final entry in paidByLabels.entries) ...[
                  Expanded(
                    child: PaidByButton(
                      label: entry.value,
                      selected: _paidBy == entry.key,
                      onTap: _saving ? null : () => setState(() => _paidBy = entry.key),
                    ),
                  ),
                  if (entry.key != paidByLabels.keys.last) const SizedBox(width: 12),
                ],
              ],
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _valid && !_saving ? _save : null,
            child: _saving
                ? SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: t.primaryForeground),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
