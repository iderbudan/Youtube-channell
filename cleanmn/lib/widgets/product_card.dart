import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../state/cart_provider.dart';
import '../utils/format.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(product.id));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: ProductImage(product: product, size: 52),
              ),
            ),
            const SizedBox(height: 8),
            Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(height: 1.2)),
            Text(product.unit,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Text(formatMnt(product.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: Badge(
                  isLabelVisible: inCart > 0,
                  label: Text('$inCart'),
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    tooltip: 'Сагсанд нэмэх',
                    onPressed: product.inStock
                        ? () {
                            context.read<CartProvider>().add(product);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content: Text('${product.name} сагсанд нэмэгдлээ'),
                                duration: const Duration(seconds: 1),
                              ));
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
