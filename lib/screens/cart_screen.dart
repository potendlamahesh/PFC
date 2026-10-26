import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/cart.dart';
import '../data/models/catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(cartProvider);
    final cart = state.cart;
    final shop = ref.watch(homeProvider).valueOrNull?.shop;

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your cart')),
        body: EmptyState(
          emoji: '🔐',
          title: 'Log in to order',
          message: 'Your cart is saved to your account so you can pick up '
              'where you left off on any device.',
          actionLabel: 'Log in',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: state.mutating ? null : _confirmClear,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: state.loading
          ? const _CartSkeleton()
          : cart.isEmpty
              ? EmptyState(
                  emoji: '🛒',
                  title: 'Your cart is empty',
                  message: 'Add something crispy and it will show up here.',
                  actionLabel: 'Browse the menu',
                  onAction: () => goToTab(ref, 1),
                )
              : RefreshIndicator(
                  color: AppColors.red,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.read(cartProvider.notifier).load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 220),
                    children: [
                      ...cart.items.map(
                        (item) => _CartLine(
                          item: item,
                          busy: state.mutating,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _CouponBox(
                        controller: _couponController,
                        applied: cart.couponCode,
                        busy: state.mutating,
                      ),
                      const SizedBox(height: 20),
                      _BillCard(cart: cart),
                      if (!cart.meetsMinimum && cart.minOrderValue > 0) ...[
                        const SizedBox(height: 14),
                        _MinimumWarning(
                          short: cart.minOrderValue - cart.subtotal,
                        ),
                      ],
                      if (shop != null && !shop.canOrder) ...[
                        const SizedBox(height: 14),
                        _ClosedWarning(message: shop.closedMessage),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _CheckoutBar(cart: cart, canOrder: shop?.canOrder ?? true),
    );
  }

  Future<void> _confirmClear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Empty the cart?'),
        content: const Text('This removes everything you have added.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Empty it'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(cartProvider.notifier).clear();
    }
  }
}

// ------------------------------------------------------------------- line

class _CartLine extends ConsumerWidget {
  final CartItem item;
  final bool busy;
  const _CartLine({required this.item, required this.busy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          FoodImage(path: item.productImage, width: 62, height: 62),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FoodTypeDot(
                      item.foodType.toUpperCase() == 'NONVEG'
                          ? FoodType.nonVeg
                          : item.foodType.toUpperCase() == 'EGG'
                              ? FoodType.egg
                              : FoodType.veg,
                      size: 12,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.variantLabel}  ·  ${rupees(item.unitPrice)} each',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    QuantityStepper(
                      quantity: item.quantity,
                      busy: busy,
                      height: 34,
                      onAdd: () => notifier.increment(item),
                      onRemove: () => notifier.decrement(item),
                    ),
                    const Spacer(),
                    Text(
                      rupees(item.lineTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- coupon

class _CouponBox extends ConsumerWidget {
  final TextEditingController controller;
  final String? applied;
  final bool busy;

  const _CouponBox({
    required this.controller,
    required this.applied,
    required this.busy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (applied != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.green.withOpacity(.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded,
                size: 18, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$applied applied',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => ref.read(cartProvider.notifier).removeCoupon(),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Have a coupon code?',
              prefixIcon: Icon(Icons.local_offer_outlined,
                  color: AppColors.textFaint, size: 19),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final code = controller.text.trim();
                    if (code.isEmpty) return;
                    final ok = await ref
                        .read(cartProvider.notifier)
                        .applyCoupon(code);
                    if (!context.mounted) return;
                    if (ok) {
                      controller.clear();
                      showToast(context, 'Coupon applied');
                    } else {
                      showToast(
                        context,
                        ref.read(cartProvider).error ?? 'Invalid coupon.',
                        error: true,
                      );
                    }
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(90, 54),
            ),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- bill

class _BillCard extends StatelessWidget {
  final Cart cart;
  const _BillCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Bill details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _line('Item total', cart.subtotal),
          if (cart.packingFee > 0) _line('Packing', cart.packingFee),
          _line(
            'Delivery',
            cart.deliveryFee,
            freeLabel: cart.deliveryFee == 0 ? 'FREE' : null,
          ),
          if (cart.gstAmount > 0) _line('Taxes', cart.gstAmount),
          if (cart.discount > 0)
            _line('Discount', -cart.discount, color: AppColors.green),
          const Divider(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'To pay',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                rupees(cart.total),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(
    String label,
    double value, {
    Color? color,
    String? freeLabel,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              freeLabel ??
                  (value < 0 ? '− ${rupees(-value)}' : rupees(value)),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: freeLabel != null ? AppColors.green : color,
              ),
            ),
          ],
        ),
      );
}

class _MinimumWarning extends StatelessWidget {
  final double short;
  const _MinimumWarning({required this.short});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber.withOpacity(.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_shopping_cart_rounded,
              size: 19, color: AppColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add ${rupees(short)} more to reach the minimum order.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedWarning extends StatelessWidget {
  final String message;
  const _ClosedWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.red.withOpacity(.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, size: 19, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty
                  ? 'The kitchen is closed right now.'
                  : message,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  final Cart cart;
  final bool canOrder;
  const _CheckoutBar({required this.cart, required this.canOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = !canOrder || !cart.meetsMinimum;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rupees(cart.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${cart.itemCount} '
                    '${cart.itemCount == 1 ? "item" : "items"}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ElevatedButton(
                  onPressed: blocked
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          ),
                  child: Text(
                    !canOrder
                        ? 'Kitchen closed'
                        : !cart.meetsMinimum
                            ? 'Add more to checkout'
                            : 'Checkout',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerBox(height: 100),
          ),
        ),
        const SizedBox(height: 16),
        const ShimmerBox(height: 220),
      ],
    );
  }
}
