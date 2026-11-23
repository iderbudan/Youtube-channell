import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/orders_provider.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersProvider>().refreshActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final orders = provider.orders;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Миний захиалгууд')),
      body: RefreshIndicator(
        onRefresh: provider.refreshActive,
        child: orders.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('Захиалга алга байна', textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _OrderTile(order: orders[i]),
              ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.number,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatDateTime(order.createdAt)} · ${order.itemCount} бараа',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.lines.map((l) => l.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatMnt(order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
