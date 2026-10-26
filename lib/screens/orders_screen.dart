import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your orders')),
        body: EmptyState(
          emoji: '🧾',
          title: 'Log in to see orders',
          message: 'Your order history lives with your account.',
          actionLabel: 'Log in',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      );
    }

    final orders = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 128),
            ),
          ),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              emoji: '🍗',
              title: 'No orders yet',
              message: 'Once you order something it will show up here, '
                  'with live status while it is being made.',
              actionLabel: 'Start an order',
              onAction: () => goToTab(ref, 1),
            );
          }

          final live = list.where((o) => o.isLive).toList();
          final past = list.where((o) => !o.isLive).toList();

          return RefreshIndicator(
            color: AppColors.red,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(orderListProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (live.isNotEmpty) ...[
                  const _GroupLabel('Happening now'),
                  ...live.map((o) => _OrderCard(order: o, live: true)),
                  const SizedBox(height: 10),
                ],
                if (past.isNotEmpty) ...[
                  const _GroupLabel('Earlier'),
                  ...past.map((o) => _OrderCard(order: o)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: .3,
          ),
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool live;
  const _OrderCard({required this.order, this.live = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: live ? AppColors.red.withOpacity(.5) : AppColors.stroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: order.status),
                const Spacer(),
                Text(
                  order.placedAt == null
                      ? ''
                      : DateFormat('d MMM, h:mm a').format(order.placedAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              order.items.isEmpty
                  ? 'Order #${order.orderNumber}'
                  : order.items.map((i) => i.productName).take(2).join(', ') +
                      (order.items.length > 2
                          ? ' +${order.items.length - 2} more'
                          : ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${order.orderNumber}  ·  ${order.itemCount} '
              '${order.itemCount == 1 ? "item" : "items"}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                Text(
                  rupees(order.total),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  order.paymentMethod == 'COD' ? 'Cash' : 'Paid online',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Details',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Coloured pill showing where the order is in its life.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.cancelled => AppColors.textFaint,
      OrderStatus.delivered => AppColors.green,
      OrderStatus.outForDelivery => AppColors.amber,
      _ => AppColors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            OrderStatus.label(status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
