import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._store) : _items = _store?.loadCart() ?? [];

  final LocalStore? _store;
  final List<CartItem> _items;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.fold(0, (s, i) => s + i.quantity);
  int get subtotal => _items.fold(0, (s, i) => s + i.total);
  int get deliveryFee => AppConfig.deliveryFeeFor(subtotal);
  int get total => subtotal + deliveryFee;

  /// Үнэгүй хүргэлт хүртэл үлдсэн дүн (0 бол аль хэдийн үнэгүй).
  int get untilFreeDelivery =>
      (AppConfig.freeDeliveryThreshold - subtotal).clamp(0, AppConfig.freeDeliveryThreshold);

  int quantityOf(String productId) =>
      _items.where((i) => i.product.id == productId).fold(0, (s, i) => s + i.quantity);

  void add(Product p, [int qty = 1]) {
    final existing = _items.where((i) => i.product.id == p.id).firstOrNull;
    if (existing != null) {
      existing.quantity += qty;
    } else {
      _items.add(CartItem(product: p, quantity: qty));
    }
    _changed();
  }

  void setQuantity(String productId, int qty) {
    if (qty <= 0) return remove(productId);
    final item = _items.where((i) => i.product.id == productId).firstOrNull;
    if (item == null) return;
    item.quantity = qty.clamp(1, 99);
    _changed();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  List<OrderItemRequest> toRequest() =>
      _items.map((i) => OrderItemRequest(i.product.id, i.quantity)).toList();

  void _changed() {
    _store?.saveCart(_items);
    notifyListeners();
  }
}
