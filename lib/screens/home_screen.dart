import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'main_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: home.when(
          loading: () => const _HomeSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(homeProvider),
          ),
          data: (data) => RefreshIndicator(
            color: AppColors.red,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(homeProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(shop: data.shop)),
                if (!data.shop.canOrder)
                  SliverToBoxAdapter(child: _ClosedBanner(shop: data.shop)),
                SliverToBoxAdapter(child: _HeroCard(shop: data.shop)),

                // -------------------------------------------- categories
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'What are you craving?',
                    actionLabel: 'Full menu',
                    onAction: () => goToTab(ref, 1),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryStrip(categories: data.categories),
                ),

                // ------------------------------------------- bestsellers
                if (data.bestsellers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Popular right now 🔥',
                      actionLabel: 'View all',
                      onAction: () => goToTab(ref, 1),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ProductCarousel(products: data.bestsellers),
                  ),
                ],

                // ------------------------------------------ new arrivals
                if (data.newArrivals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Just landed ✨',
                      actionLabel: 'View all',
                      onAction: () => goToTab(ref, 1),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ProductCarousel(products: data.newArrivals),
                  ),
                ],

                SliverToBoxAdapter(child: _ShopFooter(shop: data.shop)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class _Header extends ConsumerWidget {
  final Shop shop;
  const _Header({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final greeting = user == null
        ? 'Hello, Chicken Lover! 👋'
        : 'Hello, ${user.displayName.split(' ').first}! 👋';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(color: AppColors.redGlow, blurRadius: 18),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'PFC',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.white,
                letterSpacing: -.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
          _CircleIcon(
            icon: Icons.local_offer_outlined,
            badge: '%',
            onTap: () => showToast(context, 'Offers are coming soon.'),
          ),
          const SizedBox(width: 8),
          _CircleIcon(
            icon: Icons.shopping_bag_outlined,
            onTap: () => goToTab(ref, 2),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stroke),
            ),
            child: Icon(icon, size: 19, color: AppColors.textPrimary),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- hero card

class _HeroCard extends ConsumerWidget {
  final Shop shop;
  const _HeroCard({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.stroke),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A0C0C), Color(0xFF120A0A), AppColors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.tagline.isEmpty
                ? 'Crispy. Golden. Palnadu style.'
                : shop.tagline,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fresh out of the fryer in about '
            '${shop.avgDeliveryMinutes} minutes.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => goToTab(ref, 1),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Order now'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      shop.canOrder
                          ? Icons.circle
                          : Icons.nightlight_round,
                      size: 9,
                      color: shop.canOrder
                          ? AppColors.green
                          : AppColors.textFaint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shop.canOrder ? 'Open now' : 'Closed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: shop.canOrder
                              ? AppColors.green
                              : AppColors.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  final Shop shop;
  const _ClosedBanner({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shop.closedMessage.isEmpty
                  ? 'Kitchen is closed. We open at ${shop.opensAtPretty}.'
                  : shop.closedMessage,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- categories

class _CategoryStrip extends ConsumerWidget {
  final List<Category> categories;
  const _CategoryStrip({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final items = [null, ...categories];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = items[i];
          final id = c?.id ?? 0;
          final active = selected == id;

          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = id;
              goToTab(ref, 1);
            },
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: glowCircle(active: active),
                    alignment: Alignment.center,
                    child: c == null
                        ? Icon(
                            Icons.grid_view_rounded,
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 25,
                          )
                        : Text(
                            c.iconEmoji,
                            style: const TextStyle(fontSize: 27),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c?.name ?? 'All',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCarousel extends StatelessWidget {
  final List<Product> products;
  const _ProductCarousel({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 13),
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      ),
    );
  }
}

class _ShopFooter extends StatelessWidget {
  final Shop shop;
  const _ShopFooter({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          _row(Icons.schedule_rounded, 'Open hours',
              '${shop.opensAtPretty} – ${shop.closesAtPretty}'),
          const Divider(height: 24),
          _row(Icons.delivery_dining_rounded, 'Delivery',
              'Free above ${rupees(shop.freeDeliveryAbove)}'),
          const Divider(height: 24),
          _row(Icons.shopping_basket_outlined, 'Minimum order',
              rupees(shop.minOrderValue)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

// --------------------------------------------------------------- skeleton

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const ShimmerBox(width: 46, height: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 12),
                  SizedBox(height: 7),
                  ShimmerBox(width: 180, height: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const ShimmerBox(height: 170),
        const SizedBox(height: 28),
        const ShimmerBox(width: 200, height: 22),
        const SizedBox(height: 16),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => const Column(
              children: [
                ShimmerBox(width: 64, height: 64),
                SizedBox(height: 8),
                ShimmerBox(width: 52, height: 10),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const ShimmerBox(width: 180, height: 22),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 13),
            itemBuilder: (_, __) => const ShimmerBox(width: 180, height: 300),
          ),
        ),
      ],
    );
  }
}
