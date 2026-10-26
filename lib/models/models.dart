/// Plain data models mirroring the DRF serializers.
library;

double _d(dynamic v) => v == null ? 0 : double.tryParse('$v') ?? 0;
int _i(dynamic v) => v == null ? 0 : int.tryParse('$v') ?? 0;

class AppUser {
  final String id, fullName, phone, email, photoUrl, role;
  final bool isShopAdmin, phoneVerified;

  AppUser({
    required this.id,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.photoUrl = '',
    this.role = 'CUSTOMER',
    this.isShopAdmin = false,
    this.phoneVerified = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: '${j['id']}',
        fullName: j['full_name'] ?? '',
        phone: j['phone'] ?? '',
        email: j['email'] ?? '',
        photoUrl: j['photo_url'] ?? '',
        role: j['role'] ?? 'CUSTOMER',
        isShopAdmin: j['is_shop_admin'] ?? false,
        phoneVerified: j['phone_verified'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'full_name': fullName, 'phone': phone, 'email': email,
        'photo_url': photoUrl, 'role': role, 'is_shop_admin': isShopAdmin,
        'phone_verified': phoneVerified,
      };

  String get initial =>
      (fullName.isNotEmpty ? fullName : (phone.isNotEmpty ? phone : 'G'))[0].toUpperCase();
}

class ShopSettings {
  final String name, tagline, phone, whatsapp, address, closedMessage, opensAt, closesAt;
  final double latitude, longitude, deliveryRadiusKm, deliveryFee, freeDeliveryAbove;
  final double packingFee, gstPercent, minOrderValue;
  final bool isOpen, acceptingOrders, codEnabled, onlinePaymentEnabled;
  final int avgDeliveryMinutes;

  ShopSettings.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? 'Palnadu Fried Chicken',
        tagline = j['tagline'] ?? '',
        phone = j['phone'] ?? '',
        whatsapp = j['whatsapp'] ?? '',
        address = j['address'] ?? '',
        closedMessage = j['closed_message'] ?? 'We are closed right now.',
        opensAt = '${j['opens_at'] ?? ''}',
        closesAt = '${j['closes_at'] ?? ''}',
        latitude = _d(j['latitude']),
        longitude = _d(j['longitude']),
        deliveryRadiusKm = _d(j['delivery_radius_km']),
        deliveryFee = _d(j['delivery_fee']),
        freeDeliveryAbove = _d(j['free_delivery_above']),
        packingFee = _d(j['packing_fee']),
        gstPercent = _d(j['gst_percent']),
        minOrderValue = _d(j['min_order_value']),
        isOpen = j['is_open'] ?? true,
        acceptingOrders = j['accepting_orders'] ?? true,
        codEnabled = j['cod_enabled'] ?? true,
        onlinePaymentEnabled = j['online_payment_enabled'] ?? true,
        avgDeliveryMinutes = _i(j['avg_delivery_minutes']);

  bool get takingOrders => isOpen && acceptingOrders;
}

class SubCategory {
  final int id;
  final String name, slug, image;
  SubCategory.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = j['name'] ?? '',
        slug = j['slug'] ?? '',
        image = j['image'] ?? '';
}

class Category {
  final int id;
  final String name, slug, tagline, image, iconEmoji;
  final List<SubCategory> subcategories;

  Category.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = j['name'] ?? '',
        slug = j['slug'] ?? '',
        tagline = j['tagline'] ?? '',
        image = j['image'] ?? '',
        iconEmoji = j['icon_emoji'] ?? '',
        subcategories = ((j['subcategories'] ?? []) as List)
            .map((e) => SubCategory.fromJson(e))
            .toList();
}

class Variant {
  final int id;
  final String size, sizeDisplay, label;
  final double price;
  final double? mrp;
  final bool isDefault, isActive, inStock;
  final int discountPercent;

  Variant.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        size = j['size'] ?? 'REGULAR',
        sizeDisplay = j['size_display'] ?? '',
        label = j['label'] ?? '',
        price = _d(j['price']),
        mrp = j['mrp'] == null ? null : _d(j['mrp']),
        isDefault = j['is_default'] ?? false,
        isActive = j['is_active'] ?? true,
        inStock = j['in_stock'] ?? true,
        discountPercent = _i(j['discount_percent']);

  String get title => label.isNotEmpty ? label : sizeDisplay;
}

class AddOn {
  final int id;
  final String name;
  final double price;
  AddOn.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        name = j['name'] ?? '',
        price = _d(j['price']);
}

class Product {
  final String id, name, slug, shortDescription, description, image, foodType, serves;
  final int category;
  final int? subcategory;
  final String categoryName, subcategoryName;
  final bool isAvailable, isBestseller, isNew;
  final double rating;
  final int ratingCount;
  final List<Variant> variants;
  final List<AddOn> addons;

  Product.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}',
        name = j['name'] ?? '',
        slug = j['slug'] ?? '',
        shortDescription = j['short_description'] ?? '',
        description = j['description'] ?? '',
        image = j['image'] ?? '',
        foodType = j['food_type'] ?? 'NONVEG',
        serves = j['serves'] ?? '',
        category = _i(j['category']),
        subcategory = j['subcategory'] == null ? null : _i(j['subcategory']),
        categoryName = j['category_name'] ?? '',
        subcategoryName = j['subcategory_name'] ?? '',
        isAvailable = j['is_available'] ?? true,
        isBestseller = j['is_bestseller'] ?? false,
        isNew = j['is_new'] ?? false,
        rating = _d(j['rating']),
        ratingCount = _i(j['rating_count']),
        variants = ((j['variants'] ?? []) as List)
            .map((e) => Variant.fromJson(e))
            .where((v) => v.isActive)
            .toList(),
        addons = ((j['addons'] ?? []) as List).map((e) => AddOn.fromJson(e)).toList();

  bool get isVeg => foodType == 'VEG';
  Variant? get defaultVariant => variants.isEmpty
      ? null
      : variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);
  double get basePrice => defaultVariant?.price ?? 0;
  bool get soldOut => !isAvailable || variants.isEmpty || !(defaultVariant?.inStock ?? false);
}

class Banner {
  final String title, subtitle, image;
  final int? targetCategory;
  Banner.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        subtitle = j['subtitle'] ?? '',
        image = j['image'] ?? '',
        targetCategory = j['target_category'] == null ? null : _i(j['target_category']);
}

class Address {
  final int id;
  final String label, receiverName, receiverPhone, line1, line2, landmark, city, state, pincode, oneLine;
  final double? latitude, longitude;
  final bool isDefault;

  Address.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        label = j['label'] ?? 'HOME',
        receiverName = j['receiver_name'] ?? '',
        receiverPhone = j['receiver_phone'] ?? '',
        line1 = j['line1'] ?? '',
        line2 = j['line2'] ?? '',
        landmark = j['landmark'] ?? '',
        city = j['city'] ?? '',
        state = j['state'] ?? '',
        pincode = j['pincode'] ?? '',
        oneLine = j['one_line'] ?? '',
        latitude = j['latitude'] == null ? null : _d(j['latitude']),
        longitude = j['longitude'] == null ? null : _d(j['longitude']),
        isDefault = j['is_default'] ?? false;
}

class CartItem {
  final int id, variantId, quantity;
  final String productId, productName, productImage, variantLabel, foodType, note;
  final double unitPrice, lineTotal;
  final bool isAvailable;
  final List<AddOn> addons;

  CartItem.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        variantId = _i(j['variant']),
        quantity = _i(j['quantity']),
        productId = '${j['product_id']}',
        productName = j['product_name'] ?? '',
        productImage = j['product_image'] ?? '',
        variantLabel = j['variant_label'] ?? '',
        foodType = j['food_type'] ?? 'NONVEG',
        note = j['note'] ?? '',
        unitPrice = _d(j['unit_price']),
        lineTotal = _d(j['line_total']),
        isAvailable = j['is_available'] ?? true,
        addons = ((j['addons'] ?? []) as List).map((e) => AddOn.fromJson(e)).toList();
}

class Totals {
  final double subtotal, discount, deliveryFee, packingFee, tax, grandTotal;
  Totals.fromJson(Map<String, dynamic> j)
      : subtotal = _d(j['subtotal']),
        discount = _d(j['discount']),
        deliveryFee = _d(j['delivery_fee']),
        packingFee = _d(j['packing_fee']),
        tax = _d(j['tax']),
        grandTotal = _d(j['grand_total']);
}

class Cart {
  final int id, itemCount;
  final String couponCode;
  final List<CartItem> items;
  final Totals totals;

  Cart.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        itemCount = _i(j['item_count']),
        couponCode = j['coupon_code'] ?? '',
        items = ((j['items'] ?? []) as List).map((e) => CartItem.fromJson(e)).toList(),
        totals = Totals.fromJson(j['totals'] ?? {});

  bool get isEmpty => items.isEmpty;
}

class OrderItem {
  final String productName, variantLabel, imageUrl, note;
  final int quantity;
  final double unitPrice, lineTotal;
  final List<String> addonNames;

  OrderItem.fromJson(Map<String, dynamic> j)
      : productName = j['product_name'] ?? '',
        variantLabel = j['variant_label'] ?? '',
        imageUrl = j['image_url'] ?? '',
        note = j['note'] ?? '',
        quantity = _i(j['quantity']),
        unitPrice = _d(j['unit_price']),
        lineTotal = _d(j['line_total']),
        addonNames =
            ((j['addons_json'] ?? []) as List).map((e) => '${e['name']}').toList();
}

class Order {
  final String id, code, status, statusDisplay, fulfilment, receiverName, receiverPhone;
  final String addressText, paymentMode, paymentModeDisplay, paymentStatus, cookingNote, cancelReason;
  final double subtotal, discount, deliveryFee, packingFee, tax, grandTotal;
  final int totalItems, etaMinutes;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? firstItemImage, firstItemName;
  final double? latitude, longitude;

  Order.fromJson(Map<String, dynamic> j)
      : id = '${j['id'] ?? ''}',
        code = j['code'] ?? '',
        status = j['status'] ?? 'PLACED',
        statusDisplay = j['status_display'] ?? '',
        fulfilment = j['fulfilment'] ?? 'DELIVERY',
        receiverName = j['receiver_name'] ?? '',
        receiverPhone = j['receiver_phone'] ?? '',
        addressText = j['address_text'] ?? '',
        paymentMode = j['payment_mode'] ?? 'COD',
        paymentModeDisplay = j['payment_mode_display'] ?? '',
        paymentStatus = j['payment_status'] ?? 'PENDING',
        cookingNote = j['cooking_note'] ?? '',
        cancelReason = j['cancel_reason'] ?? '',
        subtotal = _d(j['subtotal']),
        discount = _d(j['discount']),
        deliveryFee = _d(j['delivery_fee']),
        packingFee = _d(j['packing_fee']),
        tax = _d(j['tax']),
        grandTotal = _d(j['grand_total']),
        totalItems = _i(j['total_items']),
        etaMinutes = _i(j['eta_minutes']),
        latitude = j['latitude'] == null ? null : _d(j['latitude']),
        longitude = j['longitude'] == null ? null : _d(j['longitude']),
        createdAt = DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
        items = ((j['items'] ?? []) as List).map((e) => OrderItem.fromJson(e)).toList(),
        firstItemImage = j['first_item']?['image'],
        firstItemName = j['first_item']?['name'];

  bool get isLive => const [
        'PLACED', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY'
      ].contains(status);
  bool get canCancel => const ['PENDING', 'PLACED', 'ACCEPTED'].contains(status);
}
