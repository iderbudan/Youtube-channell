/// Апп-ын тохиргоо.
///
/// Бодит backend-тэй ажиллуулахдаа:
///   flutter run --dart-define=API_BASE_URL=https://api.cleanmn.mn
/// Хоосон үед [MockApiService] ашиглагдана (QPay-г дуурайлгана).
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static bool get useMock => apiBaseUrl.isEmpty;

  /// Хүргэлтийн төлбөр ба үнэгүй хүргэлтийн босго (сервертэй ижил байх ёстой).
  static const deliveryFee = 5000;
  static const freeDeliveryThreshold = 50000;

  static int deliveryFeeFor(int subtotal) =>
      subtotal >= freeDeliveryThreshold || subtotal == 0 ? 0 : deliveryFee;
}
