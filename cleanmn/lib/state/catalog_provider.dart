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

  List<Product> get visible {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      if (category != null && p.category != category) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.description.toLowerCase().contains(q)) {
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
