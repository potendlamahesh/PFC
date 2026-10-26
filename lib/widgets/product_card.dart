import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/home_provider.dart';
import '../screens/product_sheet.dart';
import 'common.dart';

/// The tall card used in the "Popular right now" and "New" carousels.
/// Matches the website card: badge, heart, photo, name, blurb, rating, price, +.
class ProductCard extends ConsumerWidget {
  final Product product;
  final double width;

  const ProductCard({super.key, required this.product, this.width = 180});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
    final isFav = favourites.contains(product.id);

    return GestureDetector(
      onTap: () => ProductSheet.show(context, product),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------------------------------------------- photo
            Stack(
              children: [
                FoodImage(
                  path: product.image,
                  emoji: _emojiFor(product.categoryName),
                  width: width,
                  height: 132,
                  radius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                if (product.isBestseller || product.isNew)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: TagPill(
                      product.isBestseller ? 'BESTSELLER' : 'NEW',
                      color: product.isBestseller
                          ? AppColors.red
                          : AppColors.green,
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _HeartButton(
                    active: isFav,
                    onTap: () =>
                        ref.read(favouritesProvider.notifier).toggle(product.id),
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------- text
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: FoodTypeDot(product.foodType, size: 13),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (product.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '· ${product.defaultVariant?.label ?? 'Regular'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rupees(product.displayPrice),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _AddButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide row card used on the Menu tab list.
class ProductRow extends ConsumerWidget {
  final Product product;
  const ProductRow({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ProductSheet.show(context, product),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FoodTypeDot(product.foodType, size: 13),
                      const SizedBox(width: 7),
                      if (product.isBestseller)
                        const TagPill('BESTSELLER')
                      else if (product.isNew)
                        const TagPill('NEW', color: AppColors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating.toStringAsFixed(1)}  ·  '
                        '${product.prepMinutes} min',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    rupees(product.displayPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (product.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                FoodImage(
                  path: product.image,
                  emoji: _emojiFor(product.categoryName),
                  width: 104,
                  height: 96,
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: _AddButton(product: product, wide: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The red + button. Turns into a −/+ stepper once the item is in the cart.
class _AddButton extends ConsumerWidget {
  final Product product;
  final bool wide;
  const _AddButton({required this.product, this.wide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final variant = product.defaultVariant;
    final qty = variant == null
        ? 0
        : cartState.cart.quantityOfVariant(variant.id);

    if (!product.isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Text(
          'Sold out',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textFaint,
          ),
        ),
      );
    }

    // More than one size? Always open the sheet so the user chooses.
    if (qty > 0 && !product.hasChoices && variant != null) {
      final line = cartState.cart.lineForVariant(variant.id);
      return QuantityStepper(
        quantity: qty,
        busy: cartState.mutating,
        onAdd: () => ref.read(cartProvider.notifier).increment(line!),
        onRemove: () => ref.read(cartProvider.notifier).decrement(line!),
        height: wide ? 36 : 34,
      );
    }

    if (wide) {
      return GestureDetector(
        onTap: () => _onAdd(context, ref),
        child: Container(
          width: 94,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: const [
              BoxShadow(color: AppColors.redGlow, blurRadius: 14),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            qty > 0 ? 'ADD MORE' : 'ADD',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              letterSpacing: .5,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onAdd(context, ref),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.redGlow, blurRadius: 16)],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref) async {
    if (!ref.read(authProvider).isSignedIn) {
      showToast(context, 'Please log in to start an order.', error: true);
      return;
    }
    // Several sizes -> let the user pick in the sheet.
    if (product.hasChoices) {
      ProductSheet.show(context, product);
      return;
    }
    final variant = product.defaultVariant;
    if (variant == null) return;

    final ok = await ref.read(cartProvider.notifier).add(
          productId: product.id,
          variantId: variant.id,
        );
    if (!context.mounted) return;
    if (ok) {
      showToast(context, '${product.name} added');
    } else {
      showToast(
        context,
        ref.read(cartProvider).error ?? 'Could not add that.',
        error: true,
      );
    }
  }
}

class _HeartButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _HeartButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.55),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: active ? AppColors.red : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// A sensible emoji per category so empty photo slots still read as food.
String _emojiFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('chicken')) return '🍗';
  if (c.contains('burger')) return '🍔';
  if (c.contains('pizza')) return '🍕';
  if (c.contains('roll')) return '🌯';
  if (c.contains('sandwich')) return '🥪';
  if (c.contains('fries')) return '🍟';
  if (c.contains('waffle')) return '🧇';
  if (c.contains('ice')) return '🍦';
  if (c.contains('shake')) return '🥤';
  if (c.contains('juice')) return '🍹';
  if (c.contains('drink')) return '🥛';
  if (c.contains('mocktail')) return '🍸';
  return '🍽️';
}

String emojiForCategory(String category) => _emojiFor(category);
