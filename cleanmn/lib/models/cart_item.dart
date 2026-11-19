import 'product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  int get total => product.price * quantity;

  Map<String, dynamic> toJson() =>
      {'product': product.toJson(), 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        product: Product.fromJson(j['product'] as Map<String, dynamic>),
        quantity: (j['quantity'] as num).toInt(),
      );
}
