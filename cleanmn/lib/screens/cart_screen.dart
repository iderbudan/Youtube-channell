import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import '../utils/format.dart';
import '../widgets/summary_row.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import 'checkout_screen.dart';
import 'shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сагс'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Сагс хоослох уу?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Үгүй')),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Тийм')),
                    ],
                  ),
                );
                if (ok == true) cart.clear();
              },
              child: const Text('Хоослох'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('Сагс хоосон байна'),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => AppShell.goTo(context, 0),
                    child: const Text('Бараа сонгох'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (cart.untilFreeDelivery > 0)
                  _FreeDeliveryHint(remaining: cart.untilFreeDelivery, subtotal: cart.subtotal),
                for (final item in cart.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(item.product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) => cart.remove(item.product.id),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: ProductImage(product: item.product, size: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${item.product.unit} · ${formatMnt(item.product.price)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        QuantityStepper(
                                          compact: true,
                                          min: 0,
                                          value: item.quantity,
                                          onChanged: (v) => cart.setQuantity(item.product.id, v),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FittedBox(
                                            alignment: Alignment.centerRight,
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              formatMnt(item.total),
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _row('Барааны дүн', formatMnt(cart.subtotal)),
                    _row('Хүргэлт', cart.deliveryFee == 0 ? 'Үнэгүй' : formatMnt(cart.deliveryFee)),
                    const Divider(),
                    _row('Нийт', formatMnt(cart.total), bold: true),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      child: const Text('Захиалах'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => SummaryRow(a, b, bold: bold, large: true);
}

class _FreeDeliveryHint extends StatelessWidget {
  const _FreeDeliveryHint({required this.remaining, required this.subtotal});
  final int remaining;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Дахиад ${formatMnt(remaining)}-н бараа авбал хүргэлт үнэгүй'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: subtotal / (subtotal + remaining),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
