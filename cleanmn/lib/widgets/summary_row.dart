import 'package:material_ui/material_ui.dart';

/// "Нэр ............ дүн" мөр. Нарийн дэлгэц/том фонт дээр нэр нь шилжиж,
/// дүн нь хэзээ ч таслагдахгүй.
class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false, this.large = false});

  final String label;
  final String value;
  final bool bold;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large && bold ? 17.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : null, fontSize: size),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: size),
          ),
        ],
      ),
    );
  }
}
