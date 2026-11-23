import 'package:cleanmn/data/catalog.dart';
import 'package:cleanmn/models/order.dart';
import 'package:cleanmn/models/product.dart';
import 'package:cleanmn/state/catalog_provider.dart';
import 'package:cleanmn/services/mock_api_service.dart';
import 'package:cleanmn/state/cart_provider.dart';
import 'package:cleanmn/utils/format.dart';
import 'package:cleanmn/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMnt', () {
    test('мянгатын таслал', () {
      expect(formatMnt(0), '0₮');
      expect(formatMnt(500), '500₮');
      expect(formatMnt(12500), '12,500₮');
      expect(formatMnt(1234567), '1,234,567₮');
    });
  });

  group('validatePhone', () {
    test('зөв дугаар', () {
      expect(validatePhone('99112233'), isNull);
      expect(validatePhone('+976 8811-2233'), isNull);
      expect(validatePhone('60112233'), isNull);
    });
    test('буруу дугаар', () {
      expect(validatePhone(''), isNotNull);
      expect(validatePhone('1234567'), isNotNull);
      expect(validatePhone('51112233'), isNotNull);
      expect(validatePhone('991122334'), isNotNull);
    });
    test('normalizePhone', () {
      expect(normalizePhone('+976 9911 2233'), '99112233');
      expect(normalizePhone('97699112233'), '99112233');
    });
  });

  group('CartProvider', () {
    final soap = demoCatalog.first; // 6,500₮
    final mop = demoCatalog.firstWhere((p) => p.id == 'p07'); // 45,000₮

    test('нэмэх, тоо өөрчлөх, хасах', () {
      final cart = CartProvider(null);
      cart.add(soap);
      cart.add(soap, 2);
      expect(cart.count, 3);
      expect(cart.subtotal, 19500);
      expect(cart.deliveryFee, 5000);
      expect(cart.total, 24500);

      cart.setQuantity(soap.id, 1);
      expect(cart.subtotal, 6500);
      cart.setQuantity(soap.id, 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.deliveryFee, 0);
    });

    test('50,000₮-с дээш үнэгүй хүргэлт', () {
      final cart = CartProvider(null)
        ..add(mop)
        ..add(soap);
      expect(cart.subtotal, 51500);
      expect(cart.deliveryFee, 0);
      expect(cart.untilFreeDelivery, 0);
    });
  });

  group('MockApiService', () {
    test('захиалга → QPay → төлөгдсөн', () async {
      final api = MockApiService();
      final cart = CartProvider(null)..add(demoCatalog.first, 2);
      final order = await api.createOrder(
        cart.toRequest(),
        const DeliveryInfo(
          name: 'Бат',
          phone: '99112233',
          district: 'Баянгол',
          khoroo: '3',
          address: '12-р байр',
        ),
      );
      expect(order.status, OrderStatus.pendingPayment);
      expect(order.total, 13000 + 5000);

      final inv = await api.createQPayInvoice(order);
      expect(inv.amount, order.total);

      expect((await api.checkPayment(order)).paid, isFalse);
      final second = await api.checkPayment(order);
      expect(second.paid, isTrue);
      expect(second.order.status, OrderStatus.paid);
    });
  });

  test('Хамгийн их захиалсан: захиалгын тоогоор эрэмбэлнэ', () async {
    final catalog = CatalogProvider(MockApiService());
    await catalog.load();
    final top = catalog.popular(3);
    expect(top.length, 3);
    expect(top.first.orderCount >= top[1].orderCount, isTrue);
    expect(top[1].orderCount >= top[2].orderCount, isTrue);
    expect(top.first.name, 'Гарын шингэн саван');
    catalog.setCategory(ProductCategory.construction);
    expect(catalog.visible.every((p) => p.category == ProductCategory.construction), isTrue);
    expect(catalog.isHome, isFalse);
    catalog.resetFilters();
    expect(catalog.isHome, isTrue);
  });

  test('Order JSON round-trip', () {
    final o = Order(
      id: '1',
      number: 'CM-1',
      token: 't',
      lines: const [OrderLine(productId: 'p01', name: 'Саван', price: 6500, quantity: 2)],
      delivery: const DeliveryInfo(
        name: 'А',
        phone: '99112233',
        district: 'Хан-Уул',
        khoroo: '1',
        address: 'x',
      ),
      subtotal: 13000,
      deliveryFee: 5000,
      status: OrderStatus.delivering,
      createdAt: DateTime(2026, 1, 2, 3, 4),
      history: [StatusEvent(OrderStatus.paid, DateTime(2026, 1, 2, 3, 5))],
    );
    final back = Order.fromJson(o.toJson());
    expect(back.status, OrderStatus.delivering);
    expect(back.total, 18000);
    expect(back.lines.single.quantity, 2);
    expect(back.history.single.status, OrderStatus.paid);
  });
}
