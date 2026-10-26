import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/common.dart';
import 'address_form_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final shop = ref.watch(homeProvider).valueOrNull?.shop;

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyState(
          emoji: '👋',
          title: 'Welcome to PFC',
          message: 'Log in to order, save addresses and track deliveries.',
          actionLabel: 'Log in',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      );
    }

    final user = auth.user!;
    final addresses = ref.watch(addressListProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ------------------------------------------------------ header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.stroke),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF261010), AppColors.surface],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: AppColors.redGlow, blurRadius: 18),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+91 ${user.phone}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editName(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // --------------------------------------------------- addresses
          const _SectionLabel('Delivery addresses'),
          if (addresses.isEmpty)
            _Tile(
              icon: Icons.add_location_alt_outlined,
              title: 'Add your first address',
              subtitle: 'So we know where to bring the food',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddressFormScreen(),
                ),
              ),
            )
          else ...[
            ...addresses.map(
              (a) => _Tile(
                icon: a.label.toUpperCase() == 'WORK'
                    ? Icons.business_rounded
                    : Icons.home_rounded,
                title: a.labelPretty,
                subtitle: a.oneLine,
                trailing: a.isDefault
                    ? const TagPill('DEFAULT', color: AppColors.green)
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressFormScreen(existing: a),
                  ),
                ),
              ),
            ),
            _Tile(
              icon: Icons.add_rounded,
              title: 'Add another address',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressFormScreen()),
              ),
            ),
          ],

          // ------------------------------------------------------ orders
          const _SectionLabel('Your activity'),
          _Tile(
            icon: Icons.receipt_long_rounded,
            title: 'Order history',
            subtitle: 'Everything you have ordered',
            onTap: () => goToTab(ref, 3),
          ),
          _Tile(
            icon: Icons.favorite_border_rounded,
            title: 'Favourites',
            subtitle: '${ref.watch(favouritesProvider).length} saved items',
            onTap: () => goToTab(ref, 1),
          ),

          // ------------------------------------------------------- shop
          if (shop != null) ...[
            const _SectionLabel('Palnadu Fried Chicken'),
            if (shop.phone.isNotEmpty)
              _Tile(
                icon: Icons.call_rounded,
                title: 'Call the shop',
                subtitle: shop.phone,
                onTap: () => _launch('tel:${shop.phone}'),
              ),
            if (shop.whatsapp.isNotEmpty)
              _Tile(
                icon: Icons.chat_rounded,
                title: 'WhatsApp us',
                subtitle: shop.whatsapp,
                onTap: () => _launch(_whatsappLink(shop.whatsapp)),
              ),
            _Tile(
              icon: Icons.schedule_rounded,
              title: 'Opening hours',
              subtitle: '${shop.opensAtPretty} – ${shop.closesAtPretty}',
            ),
            _Tile(
              icon: Icons.language_rounded,
              title: 'Visit our website',
              subtitle: 'pfc.maheshp.in',
              onTap: () => _launch('https://pfc.maheshp.in'),
            ),
          ],

          // ------------------------------------------------------ logout
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.stroke),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'PFC app  ·  v1.0.0\n${AppConfig.baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textFaint,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Strips spaces, +, dashes so wa.me gets only digits.
  String _whatsappLink(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://wa.me/$digits';
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: ref.read(authProvider).user?.fullName);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    final ok =
        await ref.read(authProvider.notifier).updateProfile(fullName: name);
    if (!context.mounted) return;
    showToast(
      context,
      ok ? 'Name updated' : (ref.read(authProvider).error ?? 'Update failed'),
      error: !ok,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log out?'),
        content: const Text('You will need your phone number to log back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    goToTab(ref, 0);
    showToast(context, 'Logged out');
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
