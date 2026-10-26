import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/services/api_client.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'providers.dart';

final orderListProvider = FutureProvider<List<Order>>((ref) async {
  if (!ref.watch(authProvider).isSignedIn) return const [];
  return ref.watch(orderRepositoryProvider).fetchAll();
});

/// Live polling for a single order while it is being cooked / delivered.
final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).fetchOne(id);
});

class PlaceOrderResult {
  final Order? order;
  final String? error;
  const PlaceOrderResult.success(this.order) : error = null;
  const PlaceOrderResult.failure(this.error) : order = null;
  bool get ok => order != null;
}

class CheckoutController extends StateNotifier<bool> {
  final Ref ref;
  CheckoutController(this.ref) : super(false);

  Future<PlaceOrderResult> place({
    required int? addressId,
    required String paymentMethod,
    String deliveryType = 'DELIVERY',
    String note = '',
  }) async {
    state = true;
    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder(
            addressId: addressId,
            paymentMethod: paymentMethod,
            deliveryType: deliveryType,
            note: note,
          );
      ref.read(cartProvider.notifier).resetAfterOrder();
      ref.invalidate(orderListProvider);
      state = false;
      return PlaceOrderResult.success(order);
    } on ApiException catch (e) {
      state = false;
      return PlaceOrderResult.failure(e.message);
    } finally {
      state = false;
    }
  }

  Future<String?> cancel(String orderId) async {
    try {
      await ref.read(orderRepositoryProvider).cancel(orderId);
      ref.invalidate(orderListProvider);
      ref.invalidate(orderDetailProvider(orderId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutController, bool>(
  (ref) => CheckoutController(ref),
);
