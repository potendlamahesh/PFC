import '../../core/constants.dart';
import '../models/catalog.dart';
import '../models/parse.dart';
import '../services/api_client.dart';

class CatalogRepository {
  final ApiClient api;
  const CatalogRepository(this.api);

  /// One call gives us the whole storefront — shop, categories, products.
  Future<HomeData> fetchHome() async {
    final data = await api.get(Api.home);
    return HomeData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<Product>> fetchProducts({
    int? categoryId,
    String? search,
  }) async {
    final data = await api.get(Api.products, query: {
      if (categoryId != null) 'category': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return unwrapList(data).map(Product.fromJson).toList();
  }

  Future<Product> fetchProduct(String slug) async {
    final data = await api.get(Api.productDetail(slug));
    return Product.fromJson(Map<String, dynamic>.from(data));
  }
}
