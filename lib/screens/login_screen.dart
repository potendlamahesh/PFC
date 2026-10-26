import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

/// Step 1 of login: the phone number.
///
/// Firebase sends the SMS, not our Django server. If no code arrives, the
/// thing to check is the Firebase console (Authorized domains, SHA-1 for
/// Android, test numbers list) — never the backend.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      final ok = _phoneController.text.trim().length == 10;
      if (ok != _valid) setState(() => _valid = ok);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showToast(context, next.error!, error: true);
        ref.read(authProvider.notifier).clearError();
      }
      // Android sometimes auto-reads the SMS and signs in with no OTP screen.
      if (next.isSignedIn && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: AppColors.redGlow, blurRadius: 24),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'PFC',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Enter your number',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We will text you a 6-digit code to confirm it is you.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🇮🇳  +91',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      maxLength: 10,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        hintText: '9876543210',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: !_valid || auth.busy ? null : _send,
                child: auth.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send code'),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'By continuing you agree to our terms and privacy policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textFaint,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final phone = _phoneController.text.trim();
    final sent = await ref.read(authProvider.notifier).sendOtp(phone);
    if (!mounted || !sent) return;
    if (ref.read(authProvider).isSignedIn) return; // auto-verified

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
    );
  }
}

// -------------------------------------------------------------------- OTP

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 45;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showToast(context, next.error!, error: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            const Text(
              'Enter the code',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 14.5,
                ),
                children: [
                  const TextSpan(text: 'Sent to '),
                  TextSpan(
                    text: '+91 ${widget.phone}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 14,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '••••••',
                counterText: '',
                hintStyle: TextStyle(
                  fontSize: 30,
                  letterSpacing: 14,
                  color: AppColors.textFaint,
                ),
              ),
              onChanged: (v) {
                if (v.length == 6) _verify();
              },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Your name (new here?)',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textFaint, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.busy ? null : _verify,
              child: auth.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify and continue'),
            ),
            const SizedBox(height: 20),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Resend code in ${_secondsLeft}s',
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 13.5,
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        final ok = await ref
                            .read(authProvider.notifier)
                            .sendOtp(widget.phone);
                        if (ok && mounted) {
                          _startCountdown();
                          showToast(context, 'New code sent');
                        }
                      },
                      child: const Text('Resend code'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showToast(context, 'Enter all 6 digits.', error: true);
      return;
    }
    final ok = await ref.read(authProvider.notifier).verifyOtp(
          code,
          fullName: _nameController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      showToast(context, 'Welcome in! 🍗');
    }
  }
}
