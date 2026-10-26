import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Which bottom tab is showing. Lives outside the widget so any screen can
/// jump tabs — e.g. "Full menu →" on Home switches to the Menu tab.
final currentTabProvider = StateProvider<int>((ref) => 0);

void goToTab(WidgetRef ref, int index) =>
    ref.read(currentTabProvider.notifier).state = index;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Pull the cart once we know the user is signed in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isSignedIn) {
        ref.read(cartProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(currentTabProvider);

    // When the user logs in or out, refresh the cart to match.
    ref.listen(authProvider, (prev, next) {
      if (prev?.isSignedIn != next.isSignedIn) {
        ref.read(cartProvider.notifier).load();
      }
    });

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          MenuScreen(),
          CartScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: const _BottomBar(),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(currentTabProvider);
    final count = ref.watch(cartCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _Tab(
                icon: Icons.home_rounded,
                label: 'Home',
                active: index == 0,
                onTap: () => goToTab(ref, 0),
              ),
              _Tab(
                icon: Icons.grid_view_rounded,
                label: 'Menu',
                active: index == 1,
                onTap: () => goToTab(ref, 1),
              ),
              _CartTab(
                active: index == 2,
                count: count,
                onTap: () => goToTab(ref, 2),
              ),
              _Tab(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                active: index == 3,
                onTap: () => goToTab(ref, 3),
              ),
              _Tab(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: index == 4,
                onTap: () => goToTab(ref, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.red : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The raised red cart button in the middle of the bar.
class _CartTab extends StatelessWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;

  const _CartTab({
    required this.active,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -14),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(color: AppColors.redGlow, blurRadius: 20),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_basket_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red, width: 1.5),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                'Cart',
                style: TextStyle(
                  fontSize: 11,
                  color: active ? AppColors.red : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
