import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Bottom-nav shell: Home · Menu · Orders · Profile, with a floating cart bar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  final _pages = const [HomeScreen(), MenuScreen(), OrdersScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (cart.count > 0)
          _CartBar(
            count: cart.count,
            total: cart.grandTotal,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        Container(
          decoration: const BoxDecoration(
            color: PfcColors.ink850,
            border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
          ),
          child: NavigationBar(
            height: 66,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0x26F0A82B),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Menu'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Orders'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        ),
      ]),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;
  const _CartBar({required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                gradient: PfcColors.goldGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                      color: PfcColors.gold400.withValues(alpha: .3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.shopping_bag_rounded, color: PfcColors.onGold),
                const SizedBox(width: 10),
                Text('$count item${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: PfcColors.onGold, fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Text('₹${total.toStringAsFixed(0)}  •  View cart',
                    style: const TextStyle(
                        color: PfcColors.onGold, fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
          ),
        ),
      );
}
