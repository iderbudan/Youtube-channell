import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/product.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Нэг захиалгын мөр — сервер үнийг өөрөө тооцно (клиентэд итгэхгүй).
class OrderItemRequest {
  const OrderItemRequest(this.productId, this.quantity);
  final String productId;
  final int quantity;
  Map<String, dynamic> toJson() => {'productId': productId, 'quantity': quantity};
}

/// Төлбөр шалгасны хариу.
class PaymentCheck {
  const PaymentCheck({required this.paid, required this.order});
  final bool paid;
  final Order order;
}

abstract class ApiService {
  Future<List<Product>> fetchProducts();

  /// Захиалга үүсгэнэ (төлөв: pending_payment).
  Future<Order> createOrder(List<OrderItemRequest> items, DeliveryInfo delivery);

  /// Захиалгад QPay нэхэмжлэх үүсгэнэ (дахин дуудвал байгаа нэхэмжлэхийг буцаана).
  Future<QPayInvoice> createQPayInvoice(Order order);

  /// QPay-ээс төлбөр орсон эсэхийг шалгана.
  Future<PaymentCheck> checkPayment(Order order);

  Future<Order> fetchOrder(String id, String token);
}

class HttpApiService implements ApiService {
  HttpApiService(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl$path').replace(queryParameters: q);

  Future<dynamic> _send(Future<http.Response> req) async {
    final http.Response res;
    try {
      res = await req.timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Сервертэй холбогдож чадсангүй. Интернэтээ шалгана уу.');
    }
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      final msg = body is Map ? body['error'] as String? : null;
      throw ApiException(msg ?? 'Алдаа гарлаа (${res.statusCode})');
    }
    return body;
  }

  static const _json = {'Content-Type': 'application/json'};

  @override
  Future<List<Product>> fetchProducts() async {
    final data = await _send(_client.get(_u('/api/products')));
    return (data as List).map((p) => Product.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<Order> createOrder(List<OrderItemRequest> items, DeliveryInfo delivery) async {
    final data = await _send(
      _client.post(
        _u('/api/orders'),
        headers: _json,
        body: jsonEncode({'items': items.map((i) => i.toJson()).toList(), 'delivery': delivery.toJson()}),
      ),
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<QPayInvoice> createQPayInvoice(Order order) async {
    final data = await _send(
      _client.post(_u('/api/orders/${order.id}/qpay', {'token': order.token}), headers: _json),
    );
    return QPayInvoice.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PaymentCheck> checkPayment(Order order) async {
    final data =
        await _send(
              _client.post(
                _u('/api/orders/${order.id}/payment-check', {'token': order.token}),
                headers: _json,
              ),
            )
            as Map<String, dynamic>;
    return PaymentCheck(
      paid: data['paid'] as bool,
      order: Order.fromJson(data['order'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Order> fetchOrder(String id, String token) async {
    final data = await _send(_client.get(_u('/api/orders/$id', {'token': token})));
    return Order.fromJson(data as Map<String, dynamic>);
  }
}
