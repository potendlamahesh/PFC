import '../../core/constants.dart';
import 'address.dart';
import 'parse.dart';

class OrderItem {
  final int id;
  final String productName;
  final String productImage;
  final String variantLabel;
  final String foodType;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderItem({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.variantLabel,
    required this.foodType,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    final unit = asDouble(j['unit_price'] ?? j['price']);
    final qty = asInt(j['quantity'], 1);
    return OrderItem(
      id: asInt(j['id']),
      productName: asString(j['product_name'] ?? j['name']),
      productImage: asString(j['product_image'] ?? j['image']),
      variantLabel: asString(j['variant_label'] ?? j['variant'], 'Regular'),
      foodType: asString(j['food_type'], 'VEG'),
      unitPrice: unit,
      quantity: qty,
      lineTotal: asDouble(j['line_total'] ?? j['total'], unit * qty),
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItem> items;

  final double subtotal;
  final double deliveryFee;
  final double packingFee;
  final double gstAmount;
  final double discount;
  final double total;

  final Address? address;
  final String deliveryType; // DELIVERY / PICKUP
  final String note;

  final DateTime? placedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int etaMinutes;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.packingFee,
    required this.gstAmount,
    required this.discount,
    required this.total,
    required this.address,
    required this.deliveryType,
    required this.note,
    required this.placedAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.etaMinutes,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: asString(j['id']),
        orderNumber: asString(j['order_number'] ?? j['code'] ?? j['id']),
        status: asString(j['status'], OrderStatus.placed).toUpperCase(),
        paymentMethod: asString(j['payment_method'], 'COD').toUpperCase(),
        paymentStatus: asString(j['payment_status'], 'PENDING').toUpperCase(),
        items: asMapList(j['items']).map(OrderItem.fromJson).toList(),
        subtotal: asDouble(j['subtotal'] ?? j['items_total']),
        deliveryFee: asDouble(j['delivery_fee']),
        packingFee: asDouble(j['packing_fee']),
        gstAmount: asDouble(j['gst_amount'] ?? j['tax']),
        discount: asDouble(j['discount'] ?? j['discount_amount']),
        total: asDouble(j['total'] ?? j['grand_total']),
        address: j['address'] is Map
            ? Address.fromJson(Map<String, dynamic>.from(j['address']))
            : null,
        deliveryType: asString(j['delivery_type'], 'DELIVERY').toUpperCase(),
        note: asString(j['note'] ?? j['instructions']),
        placedAt: asDate(j['placed_at'] ?? j['created_at']),
        deliveredAt: asDate(j['delivered_at']),
        cancelledAt: asDate(j['cancelled_at']),
        etaMinutes: asInt(j['eta_minutes'], 35),
      );

  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isLive => !isCancelled && !isDelivered;

  /// Only lets the user cancel while the kitchen hasn't started.
  bool get canCancel =>
      status == OrderStatus.placed || status == OrderStatus.accepted;

  /// 0..1 progress along the status flow, for the tracker bar.
  double get progress {
    if (isCancelled) return 0;
    final i = OrderStatus.flow.indexOf(status);
    if (i < 0) return 0;
    return (i + 1) / OrderStatus.flow.length;
  }

  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);
}
