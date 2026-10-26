import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// Bottom sheet for one product: photo, description, size choice, add to cart.
class ProductSheet extends ConsumerStatefulWidget {
  final Product product;
  const ProductSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<ProductSheet> {
  late Variant? _variant;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _variant = widget.product.defaultVariant;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final busy = ref.watch(cartProvider).mutating;
    final lineTotal = (_variant?.price ?? p.basePrice) * _qty;

    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .5,
      maxChildSize: .95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    FoodImage(
                      path: p.image,
                      emoji: emojiForCategory(p.categoryName),
                      height: 190,
                      radius: BorderRadius.circular(AppRadius.lg),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FoodTypeDot(p.foodType, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 17, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text(
                          p.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.schedule_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${p.prepMinutes} min',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            p.categoryName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (p.shortDescription.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        p.shortDescription,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.55,
                          fontSize: 14.5,
                        ),
                      ),
                    ],

                    // ------------------------------------------- sizes
                    if (p.variants.length > 1) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Choose a size',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...p.variants.where((v) => v.isActive).map(
                            (v) => _VariantTile(
                              variant: v,
                              selected: _variant?.id == v.id,
                              onTap: () => setState(() => _variant = v),
                            ),
                          ),
                    ],

                    // ---------------------------------------- quantity
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        QuantityStepper(
                          quantity: _qty,
                          height: 42,
                          onAdd: () => setState(() => _qty++),
                          onRemove: () =>
                              setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------------------------------- add to cart
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: ElevatedButton(
                    onPressed:
                        busy || !p.isAvailable ? null : () => _addToCart(),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            p.isAvailable
                                ? 'Add to cart  ·  ${rupees(lineTotal)}'
                                : 'Sold out',
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    if (!ref.read(authProvider).isSignedIn) {
      Navigator.pop(context);
      showToast(context, 'Please log in to start an order.', error: true);
      return;
    }
    final v = _variant;
    if (v == null) return;

    final ok = await ref.read(cartProvider.notifier).add(
          productId: widget.product.id,
          variantId: v.id,
          quantity: _qty,
        );

    if (!mounted) return;
    Navigator.pop(context);
    if (ok) {
      showToast(context, '${widget.product.name} added to cart');
    } else {
      showToast(
        context,
        ref.read(cartProvider).error ?? 'Could not add that.',
        error: true,
      );
    }
  }
}

class _VariantTile extends StatelessWidget {
  final Variant variant;
  final bool selected;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !variant.inStock;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.red.withOpacity(.12) : AppColors.black,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.stroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.red : AppColors.textFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                variant.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: disabled ? AppColors.textFaint : AppColors.textPrimary,
                ),
              ),
            ),
            if (disabled)
              const Text(
                'Out of stock',
                style: TextStyle(fontSize: 12, color: AppColors.textFaint),
              )
            else ...[
              if (variant.hasDiscount) ...[
                Text(
                  rupees(variant.mrp!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textFaint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                rupees(variant.price),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
