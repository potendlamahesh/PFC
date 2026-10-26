import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/catalog.dart';
import 'providers.dart';

/// The storefront. Everything on the Home and Menu tabs reads from here.
final homeProvider = FutureProvider<HomeData>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchHome();
});

/// Which category chip is selected. 0 = "All".
final selectedCategoryProvider = StateProvider<int>((ref) => 0);

/// The search box text on the Menu tab.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Products after the category chip and the search box are applied.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final home = ref.watch(homeProvider).valueOrNull;
  if (home == null) return const [];

  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  var list = categoryId == 0
      ? home.products
      : home.products.where((p) => p.categoryId == categoryId).toList();

  if (query.isNotEmpty) {
    list = list.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.shortDescription.toLowerCase().contains(query) ||
          p.categoryName.toLowerCase().contains(query);
    }).toList();
  }

  return list;
});

/// Favourites are device-local for now — there is no endpoint for them yet.
class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier() : super(<String>{});

  void toggle(String productId) {
    final next = Set<String>.from(state);
    next.contains(productId) ? next.remove(productId) : next.add(productId);
    state = next;
  }

  bool has(String productId) => state.contains(productId);
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<String>>(
  (ref) => FavouritesNotifier(),
);
