import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_provider.dart';
import '../utils/format.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import 'shell.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(p.category.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Hero(
              tag: 'product-${p.id}',
              child: ProductImage(product: p, size: 110, radius: 24),
            ),
          ),
          const SizedBox(height: 20),
          Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(p.unit, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(
            formatMnt(p.price),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(p.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                p.inStock ? Icons.check_circle : Icons.remove_circle_outline,
                size: 18,
                color: p.inStock ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(p.inStock ? 'Бэлэн байгаа' : 'Дууссан'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: p.inStock
                      ? () {
                          context.read<CartProvider>().add(p, _qty);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_qty ширхэг сагсанд нэмэгдлээ'),
                              action: SnackBarAction(
                                label: 'Сагс руу',
                                onPressed: () {
                                  Navigator.of(context).popUntil((r) => r.isFirst);
                                  AppShell.goTo(context, 1);
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text('Сагслах · ${formatMnt(p.price * _qty)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
