import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../state/cart_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.rank, this.hero = true});
  final Product product;

  /// "Хамгийн их захиалсан" жагсаалт дахь байр (№1, №2 ...).
  final int? rank;

  /// Нэг бараа хоёр газар (их захиалсан + бүх бараа) гарахад Hero давхцахгүй байх.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(product.id));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hero
                          ? Hero(
                              tag: 'product-${product.id}',
                              child: ProductImage(product: product, size: 52),
                            )
                          : ProductImage(product: product, size: 52),
                    ),
                    if (rank != null)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Brand.peach,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '№$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
              ),
              Text(
                rank != null ? '${product.unit} · ${product.orderCount} захиалга' : product.unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMnt(product.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} сагсанд нэмэгдлээ'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                              }
                            : null,
                        icon: const Icon(Icons.add_shopping_cart),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
