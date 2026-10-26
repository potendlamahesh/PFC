import 'parse.dart';
import 'shop.dart';

export 'shop.dart';

class SubCategory {
  final int id;
  final String name;
  final String slug;
  final int sortOrder;

  const SubCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
  });

  factory SubCategory.fromJson(Map<String, dynamic> j) => SubCategory(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        sortOrder: asInt(j['sort_order']),
      );
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String tagline;
  final String image;
  final String iconEmoji;
  final int sortOrder;
  final bool isActive;
  final List<SubCategory> subcategories;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.tagline,
    required this.image,
    required this.iconEmoji,
    required this.sortOrder,
    required this.isActive,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: asInt(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        tagline: asString(j['tagline']),
        image: asString(j['image']),
        iconEmoji: asString(j['icon_emoji'], '🍽️'),
        sortOrder: asInt(j['sort_order']),
        isActive: asBool(j['is_active'], true),
        subcategories: asMapList(j['subcategories'])
            .map(SubCategory.fromJson)
            .toList(),
      );
}

/// One buyable size of a product. Every product has at least one.
class Variant {
  final int id;
  final String size;
  final String sizeDisplay;
  final String label;
  final double price;
  final double? mrp;
  final String sku;
  final bool isDefault;
  final bool isActive;
  final int stockQty;
  final bool trackStock;
  final int discountPercent;
  final bool inStock;

  const Variant({
    required this.id,
    required this.size,
    required this.sizeDisplay,
    required this.label,
    required this.price,
    required this.mrp,
    required this.sku,
    required this.isDefault,
    required this.isActive,
    required this.stockQty,
    required this.trackStock,
    required this.discountPercent,
    required this.inStock,
  });

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: asInt(j['id']),
        size: asString(j['size']),
        sizeDisplay: asString(j['size_display']),
        label: asString(j['label'], asString(j['size_display'], 'Regular')),
        price: asDouble(j['price']),
        mrp: j['mrp'] == null ? null : asDouble(j['mrp']),
        sku: asString(j['sku']),
        isDefault: asBool(j['is_default']),
        isActive: asBool(j['is_active'], true),
        stockQty: asInt(j['stock_qty']),
        trackStock: asBool(j['track_stock']),
        discountPercent: asInt(j['discount_percent']),
        inStock: asBool(j['in_stock'], true),
      );

  bool get hasDiscount => mrp != null && mrp! > price;
}

enum FoodType { veg, nonVeg, egg }

class Product {
  final String id; // UUID from the server
  final String name;
  final String slug;
  final String shortDescription;
  final String image;
  final String foodTypeRaw;
  final int spiceLevel;
  final String serves;
  final int prepMinutes;
  final bool isAvailable;
  final bool isBestseller;
  final bool isNew;
  final double rating;
  final int ratingCount;
  final int categoryId;
  final String categoryName;
  final int? subcategoryId;
  final String subcategoryName;
  final double basePrice;
  final List<Variant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.image,
    required this.foodTypeRaw,
    required this.spiceLevel,
    required this.serves,
    required this.prepMinutes,
    required this.isAvailable,
    required this.isBestseller,
    required this.isNew,
    required this.rating,
    required this.ratingCount,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.basePrice,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: asString(j['id']),
        name: asString(j['name']),
        slug: asString(j['slug']),
        shortDescription: asString(j['short_description']),
        image: asString(j['image']),
        foodTypeRaw: asString(j['food_type'], 'VEG'),
        spiceLevel: asInt(j['spice_level'], 1),
        serves: asString(j['serves']),
        prepMinutes: asInt(j['prep_minutes'], 15),
        isAvailable: asBool(j['is_available'], true),
        isBestseller: asBool(j['is_bestseller']),
        isNew: asBool(j['is_new']),
        rating: asDouble(j['rating'], 4.3),
        ratingCount: asInt(j['rating_count']),
        categoryId: asInt(j['category']),
        categoryName: asString(j['category_name']),
        subcategoryId: j['subcategory'] == null ? null : asInt(j['subcategory']),
        subcategoryName: asString(j['subcategory_name']),
        basePrice: asDouble(j['base_price']),
        variants: asMapList(j['variants']).map(Variant.fromJson).toList(),
      );

  FoodType get foodType {
    switch (foodTypeRaw.toUpperCase()) {
      case 'NONVEG':
      case 'NON_VEG':
        return FoodType.nonVeg;
      case 'EGG':
        return FoodType.egg;
      default:
        return FoodType.veg;
    }
  }

  /// The variant we preselect when the user taps +.
  Variant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => v.isDefault && v.isActive,
      orElse: () => variants.firstWhere(
        (v) => v.isActive,
        orElse: () => variants.first,
      ),
    );
  }

  bool get hasChoices => variants.length > 1;
  double get displayPrice => defaultVariant?.price ?? basePrice;
}

/// Optional extras (dips, drinks) the server may attach to a product.
class Addon {
  final int id;
  final String name;
  final double price;
  final bool isActive;

  const Addon({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
  });

  factory Addon.fromJson(Map<String, dynamic> j) => Addon(
        id: asInt(j['id']),
        name: asString(j['name']),
        price: asDouble(j['price']),
        isActive: asBool(j['is_active'], true),
      );
}

/// The whole /api/home/ payload in one object.
class HomeData {
  final Shop shop;
  final List<PromoBanner> banners;
  final List<Category> categories;
  final List<Product> bestsellers;
  final List<Product> newArrivals;
  final List<Product> products;
  final List<Addon> addons;

  const HomeData({
    required this.shop,
    required this.banners,
    required this.categories,
    required this.bestsellers,
    required this.newArrivals,
    required this.products,
    required this.addons,
  });

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
        shop: Shop.fromJson(Map<String, dynamic>.from(j['shop'] ?? {})),
        banners: asMapList(j['banners']).map(PromoBanner.fromJson).toList(),
        categories: asMapList(j['categories']).map(Category.fromJson).toList(),
        bestsellers: asMapList(j['bestsellers']).map(Product.fromJson).toList(),
        newArrivals: asMapList(j['new_arrivals']).map(Product.fromJson).toList(),
        products: asMapList(j['products']).map(Product.fromJson).toList(),
        addons: asMapList(j['addons']).map(Addon.fromJson).toList(),
      );

  List<Product> productsInCategory(int categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();
}
