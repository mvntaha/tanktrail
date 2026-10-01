import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';

/// Big two-way choice for who paid (company cash / own money).
class PaidByButton extends StatelessWidget {
  const PaidByButton({super.key, required this.label, required this.selected, required this.onTap});

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
