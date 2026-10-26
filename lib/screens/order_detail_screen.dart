import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/models/order.dart';
import '../providers/order_provider.dart';
import '../widgets/common.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  final bool justPlaced;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.justPlaced = false,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Refresh every 20s while the order is still being made, so the status
    // bar moves without the user pulling to refresh.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      final order = ref.read(orderDetailProvider(widget.orderId)).valueOrNull;
      if (order == null || order.isLive) {
        ref.invalidate(orderDetailProvider(widget.orderId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.justPlaced ? 'Order placed' : 'Order details'),
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ShimmerBox(height: 150),
            SizedBox(height: 14),
            ShimmerBox(height: 220),
            SizedBox(height: 14),
            ShimmerBox(height: 180),
          ],
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) => RefreshIndicator(
          color: AppColors.red,
          backgroundColor: AppColors.surface,
          onRefresh: () async =>
              ref.invalidate(orderDetailProvider(widget.orderId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            children: [
              if (widget.justPlaced) const _SuccessBanner(),
              _StatusCard(order: order),
              const SizedBox(height: 14),
              _ItemsCard(order: order),
              const SizedBox(height: 14),
              _BillCard(order: order),
              if (order.address != null) ...[
                const SizedBox(height: 14),
                _AddressCard(order: order),
              ],
              if (order.canCancel) ...[
                const SizedBox(height: 22),
                OutlinedButton(
                  onPressed: () => _cancel(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                  ),
                  child: const Text('Cancel this order'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(Order order) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel the order?'),
        content: const Text(
          'The kitchen has not started cooking yet, so this is free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    final error = await ref.read(checkoutProvider.notifier).cancel(order.id);
    if (!mounted) return;
    showToast(
      context,
      error ?? 'Order cancelled.',
      error: error != null,
    );
  }
}

// ---------------------------------------------------------------- pieces

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.green.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order placed!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The kitchen has it. We will keep this page updated.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Order order;
  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: order.status),
              const Spacer(),
              Text(
                '#${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (order.isCancelled)
            const Text(
              'This order was cancelled.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: order.progress,
                minHeight: 6,
                backgroundColor: AppColors.black,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.red),
              ),
            ),
            const SizedBox(height: 18),
            ...OrderStatus.flow.map((s) {
              final index = OrderStatus.flow.indexOf(s);
              final current = OrderStatus.flow.indexOf(order.status);
              final done = index <= current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 19,
                      color: done ? AppColors.red : AppColors.textFaint,
                    ),
                    const SizedBox(width: 11),
                    Text(
                      OrderStatus.label(s),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: index == current
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (order.isLive) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 17, color: AppColors.textSecondary),
                  const SizedBox(width: 9),
                  Text(
                    'Arriving in about ${order.etaMinutes} minutes',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you ordered',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...order.items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  FoodImage(path: i.productImage, width: 46, height: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${i.variantLabel}  ·  ${i.quantity} × '
                          '${rupees(i.unitPrice)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rupees(i.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          if (order.note.isNotEmpty) ...[
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 17, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.note,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Order order;
  const _BillCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _line('Item total', rupees(order.subtotal)),
          if (order.packingFee > 0)
            _line('Packing', rupees(order.packingFee)),
          _line(
            'Delivery',
            order.deliveryFee == 0 ? 'FREE' : rupees(order.deliveryFee),
            green: order.deliveryFee == 0,
          ),
          if (order.gstAmount > 0) _line('Taxes', rupees(order.gstAmount)),
          if (order.discount > 0)
            _line('Discount', '− ${rupees(order.discount)}', green: true),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                rupees(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                order.paymentMethod == 'COD'
                    ? Icons.payments_rounded
                    : Icons.credit_card_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 9),
              Text(
                order.paymentMethod == 'COD'
                    ? 'Cash on delivery'
                    : 'Paid online',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool green = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: green ? AppColors.green : null,
              ),
            ),
          ],
        ),
      );
}

class _AddressCard extends StatelessWidget {
  final Order order;
  const _AddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final a = order.address!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 20, color: AppColors.red),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.deliveryType == 'PICKUP'
                      ? 'Pickup from store'
                      : 'Delivering to ${a.labelPretty}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  a.oneLine,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (order.placedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Placed ${DateFormat('d MMM yyyy, h:mm a').format(order.placedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
