import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'token_store.dart';

/// The login flow, start to finish:
///
///   1. [sendOtp]      -> Firebase texts a 6-digit code to the phone.
///   2. [verifyOtp]    -> Firebase checks the code and hands us an ID token.
///   3. [_exchange]    -> Django verifies that ID token with firebase-admin
///                        and gives us back our own JWT pair.
///
/// Django never sends the SMS. Firebase does. That is why a wrong Firebase
/// setup shows up as "no OTP arrived" even when the backend is perfectly fine.
class AuthService {
  final ApiClient api;
  final TokenStore tokens;
  final FirebaseAuth _fb = FirebaseAuth.instance;

  AuthService(this.api, this.tokens);

  String? _verificationId;
  int? _resendToken;

  /// Phone must be 10 digits. We add +91 ourselves.
  Future<void> sendOtp({
    required String phone10,
    required void Function(String message) onFailed,
    required void Function() onCodeSent,
    void Function(AuthResult result)? onAutoVerified,
  }) async {
    await _fb.verifyPhoneNumber(
      phoneNumber: '+91$phone10',
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),

      // Android can auto-read the SMS and sign in without the user typing.
      verificationCompleted: (PhoneAuthCredential cred) async {
        try {
          final result = await _signInAndExchange(cred);
          onAutoVerified?.call(result);
        } catch (e) {
          onFailed(e.toString());
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        onFailed(_firebaseMessage(e));
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Step 2 + 3. [fullName] is only used when this phone is brand new.
  Future<AuthResult> verifyOtp({
    required String smsCode,
    String fullName = '',
  }) async {
    final vid = _verificationId;
    if (vid == null) {
      throw const ApiException('Please request the code again.');
    }
    final cred = PhoneAuthProvider.credential(
      verificationId: vid,
      smsCode: smsCode,
    );
    return _signInAndExchange(cred, fullName: fullName);
  }

  Future<AuthResult> _signInAndExchange(
    PhoneAuthCredential cred, {
    String fullName = '',
  }) async {
    final UserCredential userCred;
    try {
      userCred = await _fb.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw ApiException(_firebaseMessage(e));
    }

    final idToken = await userCred.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Could not verify that code. Try again.');
    }
    return _exchange(idToken, fullName: fullName);
  }

  /// Hands the Firebase ID token to Django and stores the JWTs we get back.
  Future<AuthResult> _exchange(String idToken, {String fullName = ''}) async {
    final body = <String, dynamic>{'id_token': idToken};
    if (fullName.trim().isNotEmpty) body['full_name'] = fullName.trim();

    final data = await api.post(Api.firebaseAuth, body: body);
    final result = AuthResult.fromJson(Map<String, dynamic>.from(data));

    if (result.access.isEmpty) {
      throw const ApiException('Login failed. Please try again.');
    }
    await tokens.save(access: result.access, refresh: result.refresh);
    return result;
  }

  /// Who am I? Used on cold start when we already hold a token.
  Future<AppUser> fetchMe() async {
    final data = await api.get(Api.me);
    final map = Map<String, dynamic>.from(data);
    // The view may wrap it as {"user": {...}} or return the user directly.
    final userMap = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'])
        : map;
    return AppUser.fromJson(userMap);
  }

  Future<AppUser> updateProfile({String? fullName, String? email}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName.trim();
    if (email != null) body['email'] = email.trim();
    final data = await api.patch(Api.me, body: body);
    final map = Map<String, dynamic>.from(data);
    final userMap = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'])
        : map;
    return AppUser.fromJson(userMap);
  }

  Future<void> logout() async {
    await tokens.clear();
    try {
      await _fb.signOut();
    } catch (_) {
      // Signing out of Firebase is best-effort; our own session is gone.
    }
  }

  static String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number does not look right.';
      case 'invalid-verification-code':
        return 'Wrong code. Please check and try again.';
      case 'session-expired':
        return 'That code expired. Ask for a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS limit reached for today. Please try again tomorrow.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'App not verified with Firebase. Check SHA-1 and the '
            'google-services.json file.';
      default:
        return e.message ?? 'Could not send the code. Please try again.';
    }
  }
}
