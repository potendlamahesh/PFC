import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/catalog.dart';
import '../providers/home_provider.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final products = ref.watch(filteredProductsProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: home.when(
          loading: () => const _MenuSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(homeProvider),
          ),
          data: (data) => Column(
            children: [
              // ------------------------------------------------ search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search for chicken, burgers, shakes…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textFaint),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 19),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),

              // ----------------------------------------- category chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, i) {
                    final c = i == 0 ? null : data.categories[i - 1];
                    final id = c?.id ?? 0;
                    final active = selected == id;

                    return GestureDetector(
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = id,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: active ? AppColors.red : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: active ? AppColors.red : AppColors.stroke,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            if (c != null) ...[
                              Text(c.iconEmoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              c?.name ?? 'All',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // ------------------------------------------------ results
              Expanded(
                child: products.isEmpty
                    ? EmptyState(
                        emoji: '🔍',
                        title: 'Nothing matched',
                        message: _searchController.text.isEmpty
                            ? 'This category is empty right now.'
                            : 'We could not find "${_searchController.text}". '
                                'Try a different word.',
                        actionLabel: 'Show everything',
                        onAction: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(selectedCategoryProvider.notifier).state = 0;
                          setState(() {});
                        },
                      )
                    : RefreshIndicator(
                        color: AppColors.red,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async => ref.invalidate(homeProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 120),
                          itemCount: products.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    18, 10, 18, 6),
                                child: Text(
                                  '${products.length} '
                                  '${products.length == 1 ? "item" : "items"}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return ProductRow(product: products[i - 1]);
                          },
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

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ShimmerBox(height: 52),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (_, __) => const ShimmerBox(width: 92, height: 38),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          6,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(height: 150),
          ),
        ),
      ],
    );
  }
}
