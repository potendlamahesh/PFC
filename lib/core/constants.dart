/// All app-wide constants live here.
class AppConfig {
  /// Your Django backend. Change this one line to point at a different server.
  static const String baseUrl = 'https://api.maheshp.in';
  static const String apiUrl = '$baseUrl/api';

  /// Media files (product images) are served by nginx from /media/
  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/media/$path';
  }
}

/// Every endpoint, in one place — mirrors pfc/urls.py on the server.
class Api {
  // auth
  static const firebaseAuth = '/auth/firebase/';
  static const refresh = '/auth/refresh/';
  static const me = '/auth/me/';

  // catalog
  static const home = '/home/';
  static const products = '/products/';
  static const categories = '/categories/';
  static String productDetail(String slug) => '/products/$slug/';

  // cart
  static const cart = '/cart/';
  static const cartAdd = '/cart/add/';
  static const cartUpdate = '/cart/update/';
  static const cartRemove = '/cart/remove/';
  static const cartClear = '/cart/clear/';

  // addresses
  static const addresses = '/addresses/';
  static String addressDetail(int id) => '/addresses/$id/';

  // checkout + orders
  static const placeOrder = '/checkout/place-order/';
  static const orders = '/orders/';
  static String orderDetail(String id) => '/orders/$id/';
  static String cancelOrder(String id) => '/orders/$id/cancel/';

  // coupons
  static const applyCoupon = '/coupons/apply/';

  // device token for push
  static const deviceToken = '/device-token/';
}

/// Order status values the backend sends back.
class OrderStatus {
  static const placed = 'PLACED';
  static const accepted = 'ACCEPTED';
  static const preparing = 'PREPARING';
  static const ready = 'READY';
  static const outForDelivery = 'OUT_FOR_DELIVERY';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';

  static const flow = [
    placed,
    accepted,
    preparing,
    ready,
    outForDelivery,
    delivered,
  ];

  static String label(String s) {
    switch (s) {
      case placed:
        return 'Order placed';
      case accepted:
        return 'Accepted';
      case preparing:
        return 'Preparing';
      case ready:
        return 'Ready';
      case outForDelivery:
        return 'On the way';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return s;
    }
  }
}
