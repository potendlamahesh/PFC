import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cart.dart';
import '../data/services/api_client.dart';
import 'auth_provider.dart';
import 'providers.dart';

class CartState {
  final Cart cart;
  final bool loading;
  final bool mutating;
  final String? error;

  const CartState({
    required this.cart,
    this.loading = false,
    this.mutating = false,
    this.error,
  });

  CartState copyWith({
    Cart? cart,
    bool? loading,
    bool? mutating,
    String? error,
    bool clearError = false,
  }) =>
      CartState(
        cart: cart ?? this.cart,
        loading: loading ?? this.loading,
        mutating: mutating ?? this.mutating,
        error: clearError ? null : (error ?? this.error),
      );
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  CartNotifier(this.ref) : super(CartState(cart: Cart.empty()));

  bool get _signedIn => ref.read(authProvider).isSignedIn;

  Future<void> load() async {
    if (!_signedIn) {
      state = CartState(cart: Cart.empty());
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final cart = await ref.read(cartRepositoryProvider).fetch();
      state = CartState(cart: cart);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<bool> add({
    required String productId,
    required int variantId,
    int quantity = 1,
  }) =>
      _run(() => ref.read(cartRepositoryProvider).add(
            productId: productId,
            variantId: variantId,
            quantity: quantity,
          ));

  Future<bool> setQuantity({required int itemId, required int quantity}) =>
      _run(() => ref
          .read(cartRepositoryProvider)
          .setQuantity(itemId: itemId, quantity: quantity));

  Future<bool> increment(CartItem item) =>
      setQuantity(itemId: item.id, quantity: item.quantity + 1);

  Future<bool> decrement(CartItem item) =>
      setQuantity(itemId: item.id, quantity: item.quantity - 1);

  Future<bool> remove(int itemId) =>
      _run(() => ref.read(cartRepositoryProvider).remove(itemId: itemId));

  Future<bool> clear() =>
      _run(() => ref.read(cartRepositoryProvider).clear());

  Future<bool> applyCoupon(String code) =>
      _run(() => ref.read(cartRepositoryProvider).applyCoupon(code));

  Future<bool> removeCoupon() =>
      _run(() => ref.read(cartRepositoryProvider).removeCoupon());

  /// After an order is placed the server empties the cart — mirror that here.
  void resetAfterOrder() => state = CartState(cart: Cart.empty());

  Future<bool> _run(Future<Cart> Function() action) async {
    if (!_signedIn) {
      state = state.copyWith(error: 'Please log in first.');
      return false;
    }
    state = state.copyWith(mutating: true, clearError: true);
    try {
      final cart = await action();
      state = CartState(cart: cart);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(mutating: false, error: e.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(ref),
);

/// Badge number on the bottom bar.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).cart.itemCount,
);
