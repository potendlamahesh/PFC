import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user.dart';
import '../data/services/api_client.dart';
import 'providers.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool busy;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );

  bool get isSignedIn => status == AuthStatus.signedIn;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AuthState());

  /// Runs once on app start. If we already hold a token we confirm it is
  /// still good by asking the server who we are.
  Future<void> restore() async {
    final tokens = ref.read(tokenStoreProvider);
    if (!tokens.hasSession) {
      state = state.copyWith(status: AuthStatus.signedOut);
      return;
    }
    try {
      final user = await ref.read(authServiceProvider).fetchMe();
      state = state.copyWith(status: AuthStatus.signedIn, user: user);
    } on ApiException {
      // Token is dead or /auth/me/ isn't wired up — treat it as signed out
      // only when the token itself was rejected.
      await ref.read(authServiceProvider).logout();
      state = state.copyWith(status: AuthStatus.signedOut, clearUser: true);
    }
  }

  // ------------------------------------------------------------ OTP flow

  Future<bool> sendOtp(String phone10) async {
    state = state.copyWith(busy: true, clearError: true);
    final completer = _Latch();

    await ref.read(authServiceProvider).sendOtp(
          phone10: phone10,
          onCodeSent: () {
            state = state.copyWith(busy: false);
            completer.done(true);
          },
          onFailed: (msg) {
            state = state.copyWith(busy: false, error: msg);
            completer.done(false);
          },
          onAutoVerified: (result) {
            state = state.copyWith(
              busy: false,
              status: AuthStatus.signedIn,
              user: result.user,
            );
            completer.done(true);
          },
        );

    return completer.future;
  }

  Future<bool> verifyOtp(String code, {String fullName = ''}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final result = await ref
          .read(authServiceProvider)
          .verifyOtp(smsCode: code, fullName: fullName);
      state = state.copyWith(
        busy: false,
        status: AuthStatus.signedIn,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
      return false;
    }
  }

  // ------------------------------------------------------------- profile

  Future<bool> updateProfile({String? fullName, String? email}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await ref
          .read(authServiceProvider)
          .updateProfile(fullName: fullName, email: email);
      state = state.copyWith(busy: false, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

/// Tiny one-shot future so the callback-style Firebase API can be awaited.
class _Latch {
  final _c = Completer<bool>();
  Future<bool> get future => _c.future;
  void done(bool v) {
    if (!_c.isCompleted) _c.complete(v);
  }
}
