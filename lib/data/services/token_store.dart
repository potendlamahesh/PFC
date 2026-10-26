import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT tokens live in the OS keychain, never in plain SharedPreferences.
class TokenStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'pfc_access';
  static const _kRefresh = 'pfc_refresh';

  String? _accessCache;
  String? _refreshCache;

  /// Read once at startup so later reads are instant.
  Future<void> load() async {
    _accessCache = await _storage.read(key: _kAccess);
    _refreshCache = await _storage.read(key: _kRefresh);
  }

  String? get access => _accessCache;
  String? get refresh => _refreshCache;
  bool get hasSession => (_accessCache ?? '').isNotEmpty;

  Future<void> save({required String access, required String refresh}) async {
    _accessCache = access;
    _refreshCache = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccess(String access) async {
    _accessCache = access;
    await _storage.write(key: _kAccess, value: access);
  }

  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
