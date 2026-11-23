import 'package:material_ui/material_ui.dart';

import '../models/product.dart';

/// Зураггүй үед ангиллын өнгөтэй дэвсгэр дээр emoji харуулна.
/// Бодит зураг нэмэхдээ энд Image.network ашиглана.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.size = 56, this.radius = 14});

  final Product product;
  final double size;
  final double radius;

  // Зөөлөн пастел өнгө — ангилал бүрт өөр.
  static const _tints = {
    ProductCategory.household: Color(0xFFE4F4FB),
    ProductCategory.disinfection: Color(0xFFE2F5EF),
    ProductCategory.construction: Color(0xFFFDF0E3),
    ProductCategory.other: Color(0xFFF1EDFA),
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
