import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/address.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/home_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/common.dart';
import 'address_form_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _deliveryType = 'DELIVERY';
  String _paymentMethod = 'COD';
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider).cart;
    final shop = ref.watch(homeProvider).valueOrNull?.shop;
    final addresses = ref.watch(addressListProvider);
    final active = ref.watch(activeAddressProvider);
    final placing = ref.watch(checkoutProvider);

    final needsAddress = _deliveryType == 'DELIVERY' && active == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ------------------------------------------- delivery or pickup
          const _Label('How do you want it?'),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  icon: Icons.delivery_dining_rounded,
                  title: 'Delivery',
                  subtitle: shop == null
                      ? ''
                      : '~${shop.avgDeliveryMinutes} min',
                  selected: _deliveryType == 'DELIVERY',
                  onTap: () => setState(() => _deliveryType = 'DELIVERY'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceCard(
                  icon: Icons.storefront_rounded,
                  title: 'Pickup',
                  subtitle: 'Collect yourself',
                  selected: _deliveryType == 'PICKUP',
                  onTap: () => setState(() => _deliveryType = 'PICKUP'),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------ address
          if (_deliveryType == 'DELIVERY') ...[
            const _Label('Deliver to'),
            addresses.when(
              loading: () => const ShimmerBox(height: 96),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(addressListProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return _AddAddressCard(onTap: _openAddressForm);
                }
                return Column(
                  children: [
                    ...list.map(
                      (a) => _AddressTile(
                        address: a,
                        selected: active?.id == a.id,
                        onTap: () => ref
                            .read(selectedAddressIdProvider.notifier)
                            .state = a.id,
                        onEdit: () => _openAddressForm(existing: a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openAddressForm(),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Add a new address'),
                    ),
                  ],
                );
              },
            ),
          ],

          // ------------------------------------------------------ payment
          const _Label('Payment'),
          if (shop?.codEnabled ?? true)
            _PaymentTile(
              icon: Icons.payments_rounded,
              title: 'Cash on delivery',
              subtitle: 'Pay when the food reaches you',
              selected: _paymentMethod == 'COD',
              onTap: () => setState(() => _paymentMethod = 'COD'),
            ),
          if (shop?.onlinePaymentEnabled ?? false)
            _PaymentTile(
              icon: Icons.credit_card_rounded,
              title: 'Pay online',
              subtitle: 'UPI, card or netbanking',
              selected: _paymentMethod == 'ONLINE',
              onTap: () => setState(() => _paymentMethod = 'ONLINE'),
            ),

          // --------------------------------------------------------- note
          const _Label('Any instructions?'),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Less spicy, ring the bell, extra napkins…',
            ),
          ),

          // --------------------------------------------------------- bill
          const _Label('Order summary'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              children: [
                ...cart.items.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          '${i.quantity}×',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            i.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          rupees(i.lineTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'To pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      rupees(cart.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: ElevatedButton(
              onPressed: placing || needsAddress ? null : _placeOrder,
              child: placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      needsAddress
                          ? 'Add an address first'
                          : 'Place order  ·  ${rupees(cart.total)}',
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddressForm({Address? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(existing: existing),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final addressId = _deliveryType == 'DELIVERY'
        ? ref.read(activeAddressProvider)?.id
        : null;

    final result = await ref.read(checkoutProvider.notifier).place(
          addressId: addressId,
          paymentMethod: _paymentMethod,
          deliveryType: _deliveryType,
          note: _noteController.text,
        );

    if (!mounted) return;

    if (result.ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: result.order!.id,
            justPlaced: true,
          ),
        ),
      );
    } else {
      // The server's own message comes through here — e.g. "Cart is empty",
      // "Below minimum order value", "Shop is closed". Show it verbatim so
      // the user knows exactly what to fix.
      showToast(context, result.error ?? 'Could not place the order.',
          error: true);
    }
  }
}

// ----------------------------------------------------------------- pieces

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 24, 2, 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.stroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 26,
                color: selected ? AppColors.red : AppColors.textSecondary),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.stroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.red : AppColors.textFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.labelPretty,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        const TagPill('DEFAULT', color: AppColors.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    address.oneLine,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (address.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAddressCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt_outlined,
                  size: 20, color: AppColors.red),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a delivery address',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'We need this before we can deliver',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.stroke,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.red : AppColors.textFaint,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 21, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
