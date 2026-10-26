import 'parse.dart';

class AppUser {
  final int id;
  final String phone;
  final String fullName;
  final String email;
  final String role;
  final String firebaseUid;

  const AppUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.role,
    required this.firebaseUid,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: asInt(j['id']),
        phone: asString(j['phone']),
        fullName: asString(j['full_name'] ?? j['name']),
        email: asString(j['email']),
        role: asString(j['role'], 'CUSTOMER').toUpperCase(),
        firebaseUid: asString(j['firebase_uid']),
      );

  /// Falls back to the phone number when the user never set a name.
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : phone;

  String get initials {
    final n = displayName.trim();
    if (n.isEmpty) return 'U';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  bool get isStaff => role == 'ADMIN' || role == 'STAFF' || role == 'OWNER';
}

/// What /api/auth/firebase/ returns.
class AuthResult {
  final bool isNewUser;
  final AppUser user;
  final String access;
  final String refresh;

  const AuthResult({
    required this.isNewUser,
    required this.user,
    required this.access,
    required this.refresh,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        isNewUser: asBool(j['is_new_user']),
        user: AppUser.fromJson(Map<String, dynamic>.from(j['user'] ?? {})),
        access: asString(j['access'] ?? j['access_token']),
        refresh: asString(j['refresh'] ?? j['refresh_token']),
      );
}
