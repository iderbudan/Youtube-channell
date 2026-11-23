enum OrderStatus {
  pendingPayment('pending_payment', 'Төлбөр хүлээгдэж байна'),
  paid('paid', 'Төлбөр төлөгдсөн'),
  preparing('preparing', 'Бэлтгэж байна'),
  delivering('delivering', 'Хүргэлтэнд гарсан'),
  delivered('delivered', 'Хүргэгдсэн'),
  cancelled('cancelled', 'Цуцлагдсан');

  const OrderStatus(this.id, this.label);
  final String id;
  final String label;

  static OrderStatus fromId(String id) => values.firstWhere((s) => s.id == id, orElse: () => pendingPayment);

  /// Хэрэглэгчид харуулах дарааллын алхмууд (цуцлагдсаныг оруулахгүй).
  static const flow = [pendingPayment, paid, preparing, delivering, delivered];
}

class DeliveryInfo {
  const DeliveryInfo({
    required this.name,
    required this.phone,
    required this.district,
    required this.khoroo,
    required this.address,
    this.note = '',
  });

  final String name;
  final String phone;
  final String district;
  final String khoroo;
  final String address;
  final String note;

  String get fullAddress => '$district дүүрэг, $khoroo-р хороо, $address';

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'district': district,
    'khoroo': khoroo,
    'address': address,
    'note': note,
  };

  factory DeliveryInfo.fromJson(Map<String, dynamic> j) => DeliveryInfo(
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    district: j['district'] as String? ?? '',
    khoroo: j['khoroo'] as String? ?? '',
    address: j['address'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );
}

class OrderLine {
  const OrderLine({required this.productId, required this.name, required this.price, required this.quantity});

  final String productId;
  final String name;
  final int price;
  final int quantity;

  int get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    productId: j['productId'] as String,
    name: j['name'] as String,
    price: (j['price'] as num).toInt(),
    quantity: (j['quantity'] as num).toInt(),
  );
}

class StatusEvent {
  const StatusEvent(this.status, this.at);
  final OrderStatus status;
  final DateTime at;

  Map<String, dynamic> toJson() => {'status': status.id, 'at': at.toUtc().toIso8601String()};

  factory StatusEvent.fromJson(Map<String, dynamic> j) =>
      StatusEvent(OrderStatus.fromId(j['status'] as String), DateTime.parse(j['at'] as String).toLocal());
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.token,
    required this.lines,
    required this.delivery,
    required this.subtotal,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    this.history = const [],
  });

  final String id;
  final String number; // Хүнд харагдах дугаар, ж: CM-240001
  final String token; // Захиалгыг харах эрх (сервер үүсгэнэ)
  final List<OrderLine> lines;
  final DeliveryInfo delivery;
  final int subtotal;
  final int deliveryFee;
  final OrderStatus status;
  final DateTime createdAt;
  final List<StatusEvent> history;

  int get total => subtotal + deliveryFee;
  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);

  Order copyWith({OrderStatus? status, List<StatusEvent>? history}) => Order(
    id: id,
    number: number,
    token: token,
    lines: lines,
    delivery: delivery,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    status: status ?? this.status,
    createdAt: createdAt,
    history: history ?? this.history,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'token': token,
    'lines': lines.map((l) => l.toJson()).toList(),
    'delivery': delivery.toJson(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'status': status.id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'history': history.map((h) => h.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    number: j['number'] as String,
    token: j['token'] as String? ?? '',
    lines: (j['lines'] as List).map((l) => OrderLine.fromJson(l as Map<String, dynamic>)).toList(),
    delivery: DeliveryInfo.fromJson(j['delivery'] as Map<String, dynamic>),
    subtotal: (j['subtotal'] as num).toInt(),
    deliveryFee: (j['deliveryFee'] as num).toInt(),
    status: OrderStatus.fromId(j['status'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    history: ((j['history'] as List?) ?? [])
        .map((h) => StatusEvent.fromJson(h as Map<String, dynamic>))
        .toList(),
  );
}

/// QPay нэхэмжлэх (сервер QPay v2 API-аас авч дамжуулна).
class QPayInvoice {
  const QPayInvoice({
    required this.invoiceId,
    required this.qrText,
    required this.amount,
    this.shortUrl,
    this.bankLinks = const [],
  });

  final String invoiceId;
  final String qrText;
  final int amount;
  final String? shortUrl;
  final List<BankLink> bankLinks;

  factory QPayInvoice.fromJson(Map<String, dynamic> j) => QPayInvoice(
    invoiceId: j['invoiceId'] as String,
    qrText: j['qrText'] as String,
    amount: (j['amount'] as num).toInt(),
    shortUrl: j['shortUrl'] as String?,
    bankLinks: ((j['urls'] as List?) ?? []).map((u) => BankLink.fromJson(u as Map<String, dynamic>)).toList(),
  );
}

class BankLink {
  const BankLink({required this.name, required this.link, this.logo});
  final String name;
  final String link;
  final String? logo;

  factory BankLink.fromJson(Map<String, dynamic> j) => BankLink(
    name: (j['description'] ?? j['name']) as String,
    link: j['link'] as String,
    logo: j['logo'] as String?,
  );
}
