enum ProductCategory {
  soap('soap', 'Саван', '🧼'),
  detergent('detergent', 'Угаалгын нунтаг', '🫧'),
  broom('broom', 'Шүүр, арчуур', '🧹'),
  disinfectant('disinfectant', 'Ариутгагч', '🧪'),
  towel('towel', 'Алчуур', '🧺'),
  other('other', 'Бусад', '🧤');

  const ProductCategory(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;

  static ProductCategory fromId(String id) =>
      values.firstWhere((c) => c.id == id, orElse: () => other);
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.description,
    required this.emoji,
    this.inStock = true,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final int price; // ₮
  final String unit;
  final String description;
  final String emoji;
  final bool inStock;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        category: ProductCategory.fromId(j['category'] as String),
        price: (j['price'] as num).toInt(),
        unit: j['unit'] as String? ?? 'ш',
        description: j['description'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🧴',
        inStock: j['inStock'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'price': price,
        'unit': unit,
        'description': description,
        'emoji': emoji,
        'inStock': inStock,
      };
}
