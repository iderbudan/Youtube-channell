import 'package:material_ui/material_ui.dart';

import '../models/order.dart';
import '../utils/format.dart';
import 'status_chip.dart';

/// Захиалгын явцыг алхам алхмаар харуулна.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.order});
  final Order order;

  static const _icons = {
    OrderStatus.pendingPayment: Icons.qr_code_2,
    OrderStatus.paid: Icons.verified_outlined,
    OrderStatus.preparing: Icons.inventory_2_outlined,
    OrderStatus.delivering: Icons.local_shipping_outlined,
    OrderStatus.delivered: Icons.home_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (order.status == OrderStatus.cancelled) {
      return ListTile(
        leading: Icon(Icons.cancel_outlined, color: scheme.error),
        title: const Text('Захиалга цуцлагдсан'),
      );
    }

    final current = OrderStatus.flow.indexOf(order.status);
    final times = {for (final h in order.history) h.status: h.at};

    return Column(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++)
          _step(context, OrderStatus.flow[i], i, current, times[OrderStatus.flow[i]],
              isLast: i == OrderStatus.flow.length - 1),
      ],
    );
  }

  Widget _step(BuildContext context, OrderStatus s, int i, int current, DateTime? at,
      {required bool isLast}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = i <= current;
    final active = i == current;
    final color = done ? statusColor(s, scheme) : scheme.outlineVariant;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 40,
          child: Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(_icons[s], size: 18, color: done ? Colors.white : color),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: i < current ? color : scheme.outlineVariant,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: done ? null : scheme.onSurfaceVariant,
                  )),
              if (at != null && done)
                Text(formatDateTime(at),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ]),
    );
  }
}
