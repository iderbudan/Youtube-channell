import 'package:material_ui/material_ui.dart';

import '../models/product.dart';

/// Зураггүй үед ангиллын өнгөтэй дэвсгэр дээр emoji харуулна.
/// Бодит зураг нэмэхдээ энд Image.network ашиглана.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.size = 56, this.radius = 14});

  final Product product;
  final double size;
  final double radius;

  static const _tints = {
    ProductCategory.soap: Color(0xFFE3F2FD),
    ProductCategory.detergent: Color(0xFFE8EAF6),
    ProductCategory.broom: Color(0xFFFFF3E0),
    ProductCategory.disinfectant: Color(0xFFE0F2F1),
    ProductCategory.towel: Color(0xFFFCE4EC),
    ProductCategory.other: Color(0xFFF1F8E9),
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = _tints[product.category]!;
    return Container(
      decoration: BoxDecoration(
        color: dark ? tint.withValues(alpha: 0.15) : tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(product.emoji, style: TextStyle(fontSize: size)),
    );
  }
}
