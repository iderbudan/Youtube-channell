import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this.api);
  final ApiService api;

  List<Product> _products = [];
  bool loading = false;
  String? error;
  ProductCategory? category;
  String query = '';

  List<Product> get all => _products;

  /// Хамгийн их захиалсан бараа (эхний [n]).
  List<Product> popular([int n = 6]) {
    final list = _products.where((p) => p.inStock && p.orderCount > 0).toList()
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    return list.take(n).toList();
  }

  /// Шүүлтүүргүй эхний байдал (нүүр хуудас).
  bool get isHome => category == null && query.trim().isEmpty;

  /// Нүүр хуудас руу буцах: ангилал, хайлтыг цэвэрлэнэ.
  void resetFilters() {
    category = null;
    query = '';
    notifyListeners();
  }

  List<Product> get visible {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      if (category != null && p.category != category) return false;
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _products = await api.fetchProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setCategory(ProductCategory? c) {
    category = c;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }
}
