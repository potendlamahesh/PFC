import 'parse.dart';

/// Mirrors ShopSetting on the server — timings, fees and switches.
class Shop {
  final int id;
  final String name;
  final String tagline;
  final String phone;
  final String whatsapp;
  final String address;
  final double latitude;
  final double longitude;

  final bool isOpen;
  final bool acceptingOrders;
  final String opensAt;
  final String closesAt;
  final String closedMessage;

  final double deliveryRadiusKm;
  final double deliveryFee;
  final double freeDeliveryAbove;
  final double packingFee;
  final double gstPercent;
  final double minOrderValue;

  final bool codEnabled;
  final bool onlinePaymentEnabled;
  final int avgDeliveryMinutes;

  const Shop({
    required this.id,
    required this.name,
    required this.tagline,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.acceptingOrders,
    required this.opensAt,
    required this.closesAt,
    required this.closedMessage,
    required this.deliveryRadiusKm,
    required this.deliveryFee,
    required this.freeDeliveryAbove,
    required this.packingFee,
    required this.gstPercent,
    required this.minOrderValue,
    required this.codEnabled,
    required this.onlinePaymentEnabled,
    required this.avgDeliveryMinutes,
  });

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: asInt(j['id']),
        name: asString(j['name'], 'Palnadu Fried Chicken'),
        tagline: asString(j['tagline']),
        phone: asString(j['phone']),
        whatsapp: asString(j['whatsapp']),
        address: asString(j['address']),
        latitude: asDouble(j['latitude']),
        longitude: asDouble(j['longitude']),
        isOpen: asBool(j['is_open'], true),
        acceptingOrders: asBool(j['accepting_orders'], true),
        opensAt: asString(j['opens_at']),
        closesAt: asString(j['closes_at']),
        closedMessage: asString(j['closed_message'], 'Kitchen is closed.'),
        deliveryRadiusKm: asDouble(j['delivery_radius_km']),
        deliveryFee: asDouble(j['delivery_fee']),
        freeDeliveryAbove: asDouble(j['free_delivery_above']),
        packingFee: asDouble(j['packing_fee']),
        gstPercent: asDouble(j['gst_percent']),
        minOrderValue: asDouble(j['min_order_value']),
        codEnabled: asBool(j['cod_enabled'], true),
        onlinePaymentEnabled: asBool(j['online_payment_enabled']),
        avgDeliveryMinutes: asInt(j['avg_delivery_minutes'], 35),
      );

  /// True when the shop will actually take an order right now.
  bool get canOrder => isOpen && acceptingOrders;

  /// "11:00:00" -> "11:00 AM"
  String get opensAtPretty => _pretty(opensAt);
  String get closesAtPretty => _pretty(closesAt);

  static String _pretty(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    var h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12 == 0 ? 12 : h % 12;
    return '$h:$m $ampm';
  }
}

/// Homepage promo banner.
class PromoBanner {
  final int id;
  final String title;
  final String subtitle;
  final String image;
  final String actionType;
  final String actionValue;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.actionType,
    required this.actionValue,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> j) => PromoBanner(
        id: asInt(j['id']),
        title: asString(j['title']),
        subtitle: asString(j['subtitle']),
        image: asString(j['image']),
        actionType: asString(j['action_type']),
        actionValue: asString(j['action_value']),
      );
}
