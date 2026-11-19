import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/orders_provider.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import 'payment_screen.dart';

/// Захиалгын төлөв хянах.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Идэвхтэй захиалгын төлөвийг 15 секунд тутам шинэчилнэ.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final p = context.read<OrdersProvider>();
    final o = p.byId(widget.orderId);
    if (o == null) return;
    if (o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled) {
      _timer?.cancel();
      return;
    }
    try {
      await p.refresh(o);
    } catch (_) {/* сүлжээний алдааг чимээгүй алгасна */}
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersProvider>().byId(widget.orderId);
    final theme = Theme.of(context);
    if (order == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Захиалга олдсонгүй')));
    }
    final d = order.delivery;
    return Scaffold(
      appBar: AppBar(title: Text(order.number)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Text('Төлөв', style: theme.textTheme.titleMedium),
            const Spacer(),
            StatusChip(status: order.status),
          ]),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: StatusTimeline(order: order))),
          const SizedBox(height: 16),
          Text('Хүргэлт', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.person_outline), title: Text(d.name), subtitle: Text(d.phone)),
              ListTile(leading: const Icon(Icons.place_outlined), title: Text(d.fullAddress),
                  subtitle: d.note.isEmpty ? null : Text(d.note)),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Бараа', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                for (final l in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text('${l.name} × ${l.quantity}')),
                      Text(formatMnt(l.total)),
                    ]),
                  ),
                const Divider(),
                _line('Хүргэлт', order.deliveryFee == 0 ? 'Үнэгүй' : formatMnt(order.deliveryFee)),
                _line('Нийт', formatMnt(order.total), bold: true),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('Захиалсан: ${formatDateTime(order.createdAt)}',
              style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
      bottomNavigationBar: order.status == OrderStatus.pendingPayment
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('QPay-ээр төлөх'),
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PaymentScreen(order: order))),
                ),
              ),
            )
          : null,
    );
  }

  Widget _line(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
          const Spacer(),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)),
        ]),
      );
}
