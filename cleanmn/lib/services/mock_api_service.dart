import 'dart:math';

import '../config.dart';
import '../data/catalog.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_service.dart';

/// Backend байхгүй үед ажиллах демо API.
///
/// * QPay нэхэмжлэхийг дуурайлгана — "Төлбөр шалгах"-ыг 2 дахь удаа дарахад
///   (эсвэл автомат шалгалтаар) төлөгдсөнд тооцно.
/// * Төлбөр төлөгдсөний дараа төлөв нь цаг хугацааны дагуу ахина
///   (бэлтгэж байна → хүргэлтэнд → хүргэгдсэн), ингэснээр хяналтын дэлгэцийг
///   туршиж болно.
class MockApiService implements ApiService {
  final _orders = <String, Order>{};
  final _checks = <String, int>{};
  final _rand = Random();
  int _seq = 240000;

  Future<void> _latency() =>
      Future.delayed(Duration(milliseconds: 300 + _rand.nextInt(400)));

  @override
  Future<List<Product>> fetchProducts() async {
    await _latency();
    return demoCatalog;
  }

  @override
  Future<Order> createOrder(List<OrderItemRequest> items, DeliveryInfo delivery) async {
    await _latency();
    if (items.isEmpty) throw ApiException('Сагс хоосон байна');
    final lines = items.map((i) {
      final p = demoCatalog.firstWhere((p) => p.id == i.productId,
          orElse: () => throw ApiException('Бүтээгдэхүүн олдсонгүй'));
      return OrderLine(productId: p.id, name: '${p.name} (${p.unit})', price: p.price, quantity: i.quantity);
    }).toList();
    final subtotal = lines.fold<int>(0, (s, l) => s + l.total);
    final now = DateTime.now();
    final order = Order(
      id: 'mock_${now.microsecondsSinceEpoch}',
      number: 'CM-${++_seq}',
      token: 'mock',
      lines: lines,
      delivery: delivery,
      subtotal: subtotal,
      deliveryFee: AppConfig.deliveryFeeFor(subtotal),
      status: OrderStatus.pendingPayment,
      createdAt: now,
      history: [StatusEvent(OrderStatus.pendingPayment, now)],
    );
    _orders[order.id] = order;
    return order;
  }

  @override
  Future<QPayInvoice> createQPayInvoice(Order order) async {
    await _latency();
    return QPayInvoice(
      invoiceId: 'INV-${order.number}',
      qrText: 'CLEANMN-DEMO|${order.number}|${order.total}',
      amount: order.total,
      shortUrl: 'https://qpay.mn/s/demo',
      bankLinks: const [
        BankLink(name: 'Хаан банк', link: 'khanbank://q?qPay_QRcode=demo'),
        BankLink(name: 'Голомт банк', link: 'socialpay-payment://q?qPay_QRcode=demo'),
        BankLink(name: 'Худалдаа хөгжлийн банк', link: 'tdbbank://q?qPay_QRcode=demo'),
        BankLink(name: 'Хас банк', link: 'xacbank://q?qPay_QRcode=demo'),
        BankLink(name: 'Төрийн банк', link: 'statebank://q?qPay_QRcode=demo'),
        BankLink(name: 'qPay хэтэвч', link: 'qpaywallet://q?qPay_QRcode=demo'),
      ],
    );
  }

  @override
  Future<PaymentCheck> checkPayment(Order order) async {
    await _latency();
    var o = _orders[order.id] ?? order;
    final n = (_checks[order.id] ?? 0) + 1;
    _checks[order.id] = n;
    if (o.status == OrderStatus.pendingPayment && n >= 2) {
      o = o.copyWith(
        status: OrderStatus.paid,
        history: [...o.history, StatusEvent(OrderStatus.paid, DateTime.now())],
      );
      _orders[o.id] = o;
    }
    return PaymentCheck(paid: o.status != OrderStatus.pendingPayment, order: o);
  }

  @override
  Future<Order> fetchOrder(String id, String token) async {
    await _latency();
    var o = _orders[id];
    if (o == null) throw ApiException('Захиалга олдсонгүй');
    // Демо: төлөгдсөнөөс хойш 20 секунд тутамд нэг алхам ахина.
    final paidAt = o.history
        .where((h) => h.status == OrderStatus.paid)
        .map((h) => h.at)
        .firstOrNull;
    if (paidAt != null && o.status != OrderStatus.cancelled) {
      const steps = [OrderStatus.preparing, OrderStatus.delivering, OrderStatus.delivered];
      final elapsed = DateTime.now().difference(paidAt).inSeconds;
      final reached = min(elapsed ~/ 20, steps.length);
      final history = [...o.history];
      for (var i = 0; i < reached; i++) {
        if (!history.any((h) => h.status == steps[i])) {
          history.add(StatusEvent(steps[i], paidAt.add(Duration(seconds: 20 * (i + 1)))));
        }
      }
      o = o.copyWith(status: history.last.status, history: history);
      _orders[id] = o;
    }
    return o;
  }
}
