import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/models/catalog.dart';

/// Money, the way the whole app shows it: ₹89 for whole rupees, ₹89.50 if not.
String rupees(double v) {
  final whole = v == v.roundToDouble();
  return '₹${whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
}

/// The little green / red / amber square next to every food name.
class FoodTypeDot extends StatelessWidget {
  final FoodType type;
  final double size;
  const FoodTypeDot(this.type, {super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      FoodType.veg => AppColors.veg,
      FoodType.nonVeg => AppColors.nonVeg,
      FoodType.egg => AppColors.egg,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: type == FoodType.nonVeg
            ? Icon(Icons.change_history_rounded,
                size: size * .62, color: color)
            : Container(
                width: size * .46,
                height: size * .46,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
      ),
    );
  }
}

/// Product photo with a graceful fallback — our products have no images yet,
/// so an empty URL must still look deliberate, never broken.
class FoodImage extends StatelessWidget {
  final String path;
  final String emoji;
  final double? width;
  final double? height;
  final BorderRadius? radius;

  const FoodImage({
    super.key,
    required this.path,
    this.emoji = '🍗',
    this.width,
    this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(path);
    final r = radius ?? BorderRadius.circular(AppRadius.md);

    Widget placeholder() => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B1B20), Color(0xFF121216)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 34)),
        );

    if (url.isEmpty) return placeholder();

    return ClipRRect(
      borderRadius: r,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerBox(width: width, height: height),
        errorWidget: (_, __, ___) => placeholder(),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? radius;
  const ShimmerBox({super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius ?? BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Used for every "nothing here yet" state so they all feel the same.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width error block with a retry button.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      emoji: '😕',
      title: 'Something went wrong',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

/// Small red pill: BESTSELLER, NEW, 20% OFF.
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const TagPill(this.text, {super.key, this.color = AppColors.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Section heading with an optional "View all →" on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.red),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// +/- control that appears once an item is in the cart.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool busy;
  final double height;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.busy = false,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove_rounded, busy ? null : onRemove),
          SizedBox(
            width: 30,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '$quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          _btn(Icons.add_rounded, busy ? null : onAdd),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: height,
          height: height,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      );
}

/// Shows a message at the bottom of the screen in the app's style.
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: error ? AppColors.red : AppColors.green,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
}
