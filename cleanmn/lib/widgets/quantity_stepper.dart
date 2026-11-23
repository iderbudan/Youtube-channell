import 'package:material_ui/material_ui.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = compact ? 32.0 : 44.0;
    Widget btn(IconData icon, String label, VoidCallback? onTap) => SizedBox(
      width: s,
      height: s,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: compact ? 18 : 22,
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, 'Хасах', value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: compact ? 28 : 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          btn(Icons.add, 'Нэмэх', value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}
