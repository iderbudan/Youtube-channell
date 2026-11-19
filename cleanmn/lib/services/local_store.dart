import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

/// Төхөөрөмж дээр сагс, сүүлийн хаяг, захиалгуудыг хадгална.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _cartKey = 'cart_v1';
  static const _deliveryKey = 'delivery_v1';
  static const _ordersKey = 'orders_v1';

  List<CartItem> loadCart() => _readList(_cartKey, CartItem.fromJson);
  Future<void> saveCart(List<CartItem> items) =>
      _prefs.setString(_cartKey, jsonEncode(items.map((i) => i.toJson()).toList()));

  DeliveryInfo? loadDelivery() {
    final s = _prefs.getString(_deliveryKey);
    if (s == null) return null;
    try {
      return DeliveryInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDelivery(DeliveryInfo d) =>
      _prefs.setString(_deliveryKey, jsonEncode(d.toJson()));

  List<Order> loadOrders() => _readList(_ordersKey, Order.fromJson);
  Future<void> saveOrders(List<Order> orders) =>
      _prefs.setString(_ordersKey, jsonEncode(orders.map((o) => o.toJson()).toList()));

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) f) {
    final s = _prefs.getString(key);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).map((e) => f(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
