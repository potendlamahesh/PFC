import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/models.dart' as models;
class CatalogProvider extends ChangeNotifier {
  final _api = ApiClient.instance;

  models.ShopSettings? shop;
  List<models.Category> categories = [];
  List<models.Product> products = [];
  List<models.Banner> banners = [];
  List<models.AddOn> addons = [];

  bool loading = false;
  String? error;

  // filters
  int? categoryId;
  int? subcategoryId;
  String foodType = '';
  String sizeLevel = '';
  String query = '';

  List<models.Product> get bestsellers {
    final b = products.where((p) => p.isBestseller).toList();
    return b.isNotEmpty ? b : products.take(8).toList();
  }

  List<models.Product> get newArrivals => products.where((p) => p.isNew).toList();

  List<models.Product> get filtered {
    var list = products;
    if (categoryId != null) list = list.where((p) => p.category == categoryId).toList();
    if (subcategoryId != null) list = list.where((p) => p.subcategory == subcategoryId).toList();
    if (foodType.isNotEmpty) list = list.where((p) => p.foodType == foodType).toList();
    if (sizeLevel.isNotEmpty) {
      list = list.where((p) => p.variants.any((v) => v.size == sizeLevel)).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.shortDescription.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<models.Product> byCategory(int id) => products.where((p) => p.category == id).toList();

  models.Category? categoryOf(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final d = await _api.get('/home/', auth: false);
      shop = models.ShopSettings.fromJson(d['shop']);
      categories = (d['categories'] as List).map((e) => models.Category.fromJson(e)).toList();
      products = (d['products'] as List).map((e) => models.Product.fromJson(e)).toList();
      banners = (d['banners'] as List).map((e) => models.Banner.fromJson(e)).toList();
      addons = (d['addons'] as List).map((e) => models.AddOn.fromJson(e)).toList();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load the menu. Pull down to retry.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<models.Product> detail(String slug) async {
    final d = await _api.get('/products/$slug/', auth: false);
    return models.Product.fromJson(d);
  }

  void setCategory(int? id) {
    categoryId = id;
    subcategoryId = null;
    notifyListeners();
  }

  void setSubcategory(int? id) {
    subcategoryId = id;
    notifyListeners();
  }

  void setFoodType(String v) {
    foodType = v;
    notifyListeners();
  }

  void setSizeLevel(String v) {
    sizeLevel = v;
    notifyListeners();
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void clearFilters() {
    categoryId = null;
    subcategoryId = null;
    foodType = '';
    sizeLevel = '';
    query = '';
    notifyListeners();
  }
}
