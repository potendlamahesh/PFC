import 'parse.dart';

/// One line in the cart. The server owns the maths — we only display it.
class CartItem {
  final int id;
  final String productId;
  final String productName;
  final String productSlug;
  final String productImage;
  final String foodType;
  final int variantId;
  final String variantLabel;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final bool isAvailable;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.productImage,
    required this.foodType,
    required this.variantId,
    required this.variantLabel,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.isAvailable,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) {
    // The serializer may nest the product or flatten it — handle both.
    final p = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'])
        : <String, dynamic>{};
    final v = j['variant'] is Map
        ? Map<String, dynamic>.from(j['variant'])
        : <String, dynamic>{};

    final unit = asDouble(
      j['unit_price'] ?? j['price'] ?? v['price'] ?? p['base_price'],
    );
    final qty = asInt(j['quantity'], 1);

    return CartItem(
      id: asInt(j['id']),
      productId: asString(j['product_id'] ?? p['id'] ?? j['product']),
      productName: asString(j['product_name'] ?? p['name']),
      productSlug: asString(j['product_slug'] ?? p['slug']),
      productImage: asString(j['product_image'] ?? p['image']),
      foodType: asString(j['food_type'] ?? p['food_type'], 'VEG'),
      variantId: asInt(j['variant_id'] ?? v['id'] ?? j['variant']),
      variantLabel: asString(
        j['variant_label'] ?? v['label'] ?? v['size_display'],
        'Regular',
      ),
      unitPrice: unit,
      quantity: qty,
      lineTotal: asDouble(j['line_total'] ?? j['total'], unit * qty),
      isAvailable: asBool(j['is_available'], true),
    );
  }
}

/// The cart plus the server-calculated bill. Never recompute these on device —
/// the server applies coupons, free-delivery thresholds and GST.
class Cart {
  final int id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double packingFee;
  final double gstAmount;
  final double discount;
  final double total;
  final String? couponCode;
  final double minOrderValue;
  final bool meetsMinimum;

  const Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.packingFee,
    required this.gstAmount,
    required this.discount,
    required this.total,
    required this.couponCode,
    required this.minOrderValue,
    required this.meetsMinimum,
  });

  factory Cart.empty() => const Cart(
        id: 0,
        items: [],
        subtotal: 0,
        deliveryFee: 0,
        packingFee: 0,
        gstAmount: 0,
        discount: 0,
        total: 0,
        couponCode: null,
        minOrderValue: 0,
        meetsMinimum: false,
      );

  factory Cart.fromJson(Map<String, dynamic> j) {
    final items = asMapList(j['items']).map(CartItem.fromJson).toList();
    final subtotal = asDouble(
      j['subtotal'] ?? j['items_total'],
      items.fold<double>(0, (s, i) => s + i.lineTotal),
    );
    final min = asDouble(j['min_order_value']);
    return Cart(
      id: asInt(j['id']),
      items: items,
      subtotal: subtotal,
      deliveryFee: asDouble(j['delivery_fee']),
      packingFee: asDouble(j['packing_fee']),
      gstAmount: asDouble(j['gst_amount'] ?? j['tax']),
      discount: asDouble(j['discount'] ?? j['discount_amount']),
      total: asDouble(j['total'] ?? j['grand_total'], subtotal),
      couponCode: j['coupon_code'] == null || asString(j['coupon_code']).isEmpty
          ? null
          : asString(j['coupon_code']),
      minOrderValue: min,
      meetsMinimum: asBool(j['meets_minimum'], min == 0 || subtotal >= min),
    );
  }

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);

  /// How many of this variant are already in the cart (drives the +/- stepper).
  int quantityOfVariant(int variantId) {
    for (final i in items) {
      if (i.variantId == variantId) return i.quantity;
    }
    return 0;
  }

  int quantityOfProduct(String productId) =>
      items.where((i) => i.productId == productId).fold<int>(
            0,
            (s, i) => s + i.quantity,
          );

  CartItem? lineForVariant(int variantId) {
    for (final i in items) {
      if (i.variantId == variantId) return i;
    }
    return null;
  }
}
