import 'package:material_ui/material_ui.dart';

import '../models/order.dart';

Color statusColor(OrderStatus s, ColorScheme c) => switch (s) {
  OrderStatus.pendingPayment => const Color(0xFFE08A00),
  OrderStatus.paid => c.primary,
  OrderStatus.preparing => const Color(0xFF3F6AD8),
  OrderStatus.delivering => const Color(0xFF7B4FD6),
  OrderStatus.delivered => const Color(0xFF2E7D32),
  OrderStatus.cancelled => c.error,
};

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
