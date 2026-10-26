import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/common.dart';

/// Phone OTP + Google sign-in. Pops with `true` once the user is signed in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static Future<bool> open(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true),
    );
    return ok ?? false;
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _codeStep = false;
  String? _hint;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _afterLogin() async {
    await context.read<CartProvider>().load();
    await context.read<OrderProvider>().loadAddresses();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.needsPhone) {
      setState(() => _codeStep = false);
      showSnack(context, 'Add your mobile number so the rider can reach you.');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _send() async {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return showSnack(context, 'Enter a valid 10-digit mobile number', error: true);
    }
    try {
      final hint = await context.read<AuthProvider>().sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeStep = true;
        _hint = hint;
      });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    try {
      if (auth.needsPhone) {
        await auth.attachPhone(phone, _code.text.trim());
      } else {
        await auth.verifyOtp(phone, _code.text.trim(), name: _name.text.trim());
      }
      await _afterLogin();
    } on ApiException catch (e) {
      if (mounted) {
        _code.clear();
        showSnack(context, e.message, error: true);
      }
    }
  }

  Future<void> _google() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (!mounted) return;
      if (context.read<AuthProvider>().isLoggedIn) await _afterLogin();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showSnack(context, 'Google sign-in failed. Use your phone number.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                  gradient: PfcColors.crustGradient, borderRadius: BorderRadius.circular(22)),
              alignment: Alignment.center,
              child: const Text('PFC',
                  style: TextStyle(
                      fontFamily: 'Bebas', fontSize: 30, color: PfcColors.onGold, letterSpacing: 1)),
            ),
            const SizedBox(height: 22),
            Text(_codeStep ? 'Enter the code' : 'Sign in to order',
                style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              _codeStep
                  ? 'Sent to +91 ${_phone.text}${_hint != null ? '  ·  test code $_hint' : ''}'
                  : 'We’ll text you a 4-digit code. No password to remember.',
              style: const TextStyle(color: PfcColors.textDim, height: 1.5),
            ),
            const SizedBox(height: 28),

            if (!_codeStep) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  counterText: '',
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(color: PfcColors.gold200, fontWeight: FontWeight.w700),
                ),
                onSubmitted: (_) => _send(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: auth.busy ? null : _send,
                child: auth.busy
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Text('Send code'),
              ),
              if (AppConfig.googleServerClientId.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: PfcColors.textMute, fontSize: 13)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: auth.busy ? null : _google,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continue with Google'),
                ),
              ],
            ] else ...[
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 16, color: PfcColors.gold200),
                decoration: const InputDecoration(counterText: '', hintText: '• • • •'),
                onChanged: (v) {
                  if (v.length == 4) _verify();
                },
              ),
              const SizedBox(height: 14),
              if (!auth.needsPhone)
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Your name (new here?)'),
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: auth.busy ? null : _verify,
                child: auth.busy
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Text('Verify & continue'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _codeStep = false),
                child: const Text('Change number'),
              ),
            ],

            const SizedBox(height: 26),
            const Text(
              'By continuing you agree to our terms. We only use your number for order updates.',
              style: TextStyle(fontSize: 12, color: PfcColors.textMute, height: 1.6),
            ),
          ]),
        ),
      ),
    );
  }
}
