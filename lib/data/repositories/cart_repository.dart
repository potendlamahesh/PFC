import '../../core/constants.dart';
import '../models/cart.dart';
import '../services/api_client.dart';

/// Every cart change goes to the server and the server returns the whole cart
/// back. We never do the maths on the device, so coupons, GST and the
/// free-delivery threshold can never drift between app and web.
class CartRepository {
  final ApiClient api;
  const CartRepository(this.api);

  Cart _parse(dynamic data) {
    final map = Map<String, dynamic>.from(data);
    // Some views answer {"cart": {...}}, others return the cart directly.
    final cartMap =
        map['cart'] is Map ? Map<String, dynamic>.from(map['cart']) : map;
    return Cart.fromJson(cartMap);
  }

  Future<Cart> fetch() async => _parse(await api.get(Api.cart));

  Future<Cart> add({
    required String productId,
    required int variantId,
    int quantity = 1,
  }) async {
    final data = await api.post(Api.cartAdd, body: {
      'product': productId,
      'product_id': productId,
      'variant': variantId,
      'variant_id': variantId,
      'quantity': quantity,
    });
    return _parse(data);
  }

  /// Set an exact quantity. Passing 0 removes the line.
  Future<Cart> setQuantity({
    required int itemId,
    required int quantity,
  }) async {
    if (quantity <= 0) return remove(itemId: itemId);
    final data = await api.post(Api.cartUpdate, body: {
      'item': itemId,
      'item_id': itemId,
      'quantity': quantity,
    });
    return _parse(data);
  }

  Future<Cart> remove({required int itemId}) async {
    final data = await api.post(Api.cartRemove, body: {
      'item': itemId,
      'item_id': itemId,
    });
    return _parse(data);
  }

  Future<Cart> clear() async => _parse(await api.post(Api.cartClear));

  Future<Cart> applyCoupon(String code) async {
    final data = await api.post(Api.applyCoupon, body: {'code': code.trim()});
    return _parse(data);
  }

  Future<Cart> removeCoupon() async {
    final data = await api.post(Api.applyCoupon, body: {'code': ''});
    return _parse(data);
  }
}
