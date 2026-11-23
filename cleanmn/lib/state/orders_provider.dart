import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this.api, this._store) : _orders = _store?.loadOrders() ?? [];

  final ApiService api;
  final LocalStore? _store;
  final List<Order> _orders;

  /// Шинэ нь эхэндээ.
  List<Order> get orders => [..._orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Order? byId(String id) => _orders.where((o) => o.id == id).firstOrNull;

  DeliveryInfo? get lastDelivery => _store?.loadDelivery();

  Future<Order> place(List<OrderItemRequest> items, DeliveryInfo delivery) async {
    final order = await api.createOrder(items, delivery);
    _orders.add(order);
    await _store?.saveDelivery(delivery);
    _changed();
    return order;
  }

  Future<QPayInvoice> invoiceFor(Order order) => api.createQPayInvoice(order);

  Future<bool> checkPayment(Order order) async {
    final res = await api.checkPayment(order);
    _upsert(res.order);
    return res.paid;
  }

  Future<Order> refresh(Order order) async {
    final fresh = await api.fetchOrder(order.id, order.token);
    _upsert(fresh);
    return fresh;
  }

  /// Дуусаагүй бүх захиалгын төлөвийг шинэчилнэ.
  Future<void> refreshActive() async {
    final active = _orders.where(
      (o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled,
    );
    await Future.wait(active.map((o) => refresh(o).catchError((_) => o)));
  }

  void _upsert(Order o) {
    final i = _orders.indexWhere((x) => x.id == o.id);
    // Серверийн хариунд token байхгүй байж болно — хуучныг хадгална.
    final merged = (o.token.isEmpty && i >= 0)
        ? Order.fromJson({...o.toJson(), 'token': _orders[i].token})
        : o;
    if (i >= 0) {
      _orders[i] = merged;
    } else {
      _orders.add(merged);
    }
    _changed();
  }

  void _changed() {
    _store?.saveOrders(_orders);
    notifyListeners();
  }
}
