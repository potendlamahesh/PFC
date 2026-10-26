import '../../core/constants.dart';
import '../models/order.dart';
import '../models/parse.dart';
import '../services/api_client.dart';

class OrderRepository {
  final ApiClient api;
  const OrderRepository(this.api);

  /// Turns the current cart into an order.
  ///
  /// A 400 here almost always means one of: cart empty, shop closed, below
  /// the minimum order value, or no address chosen. The server's own `detail`
  /// message comes through in [ApiException.message] — show it as-is.
  Future<Order> placeOrder({
    required int? addressId,
    required String paymentMethod, // COD / ONLINE
    String deliveryType = 'DELIVERY',
    String note = '',
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      'delivery_type': deliveryType,
      if (note.trim().isNotEmpty) 'note': note.trim(),
      if (addressId != null) ...{
        'address': addressId,
        'address_id': addressId,
      },
    };

    final data = await api.post(Api.placeOrder, body: body);
    final map = Map<String, dynamic>.from(data);
    final orderMap =
        map['order'] is Map ? Map<String, dynamic>.from(map['order']) : map;
    return Order.fromJson(orderMap);
  }

  Future<List<Order>> fetchAll() async {
    final data = await api.get(Api.orders);
    return unwrapList(data).map(Order.fromJson).toList();
  }

  Future<Order> fetchOne(String id) async {
    final data = await api.get(Api.orderDetail(id));
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Order> cancel(String id, {String reason = ''}) async {
    final data = await api.post(
      Api.cancelOrder(id),
      body: {if (reason.isNotEmpty) 'reason': reason},
    );
    final map = Map<String, dynamic>.from(data);
    final orderMap =
        map['order'] is Map ? Map<String, dynamic>.from(map['order']) : map;
    return Order.fromJson(orderMap);
  }
}
