import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// One HTTP client for the whole app. Handles JWT storage and silent refresh.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _access;
  String? _refresh;
  Future<bool>? _refreshing;

  /// Called when the refresh token dies — the app should send the user to login.
  void Function()? onUnauthorized;

  String? get accessToken => _access;
  bool get isLoggedIn => _access != null;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _access = p.getString('pfc_access');
    _refresh = p.getString('pfc_refresh');
  }

  Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    final p = await SharedPreferences.getInstance();
    await p.setString('pfc_access', access);
    await p.setString('pfc_refresh', refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('pfc_access');
    await p.remove('pfc_refresh');
    await p.remove('pfc_user');
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('${AppConfig.apiBase}$path').replace(
      queryParameters: (q == null || q.isEmpty) ? null : q,
    );
  }

  Map<String, String> _headers({bool json = true, bool auth = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && _access != null) 'Authorization': 'Bearer $_access',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() => http.get(_uri(path, query), headers: _headers(auth: auth)), path, auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _send(
      () => http.post(_uri(path), headers: _headers(auth: auth), body: jsonEncode(body ?? {})),
      path, auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) => _send(
      () => http.patch(_uri(path), headers: _headers(auth: auth), body: jsonEncode(body ?? {})),
      path, auth);

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _send(() => http.delete(_uri(path), headers: _headers(auth: auth)), path, auth);

  Future<dynamic> _send(
    Future<http.Response> Function() call,
    String path,
    bool auth, {
    bool allowRetry = true,
  }) async {
    http.Response res;
    try {
      res = await call().timeout(AppConfig.timeout);
    } on SocketException {
      throw ApiException('No internet connection.');
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    }

    if (res.statusCode == 401 && auth && allowRetry) {
      final ok = await _refreshAccess();
      if (ok) return _send(call, path, auth, allowRetry: false);
      await clear();
      onUnauthorized?.call();
      throw ApiException('Session expired. Please sign in again.', 401);
    }
    if (res.statusCode == 204 || res.body.isEmpty) return null;

    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (res.statusCode >= 400) {
      throw ApiException(_readError(data), res.statusCode);
    }
    return data;
  }

  String _readError(dynamic data) {
    if (data is Map) {
      if (data['detail'] is String) return data['detail'];
      for (final v in data.values) {
        if (v is String) return v;
        if (v is List && v.isNotEmpty) return '${v.first}';
      }
    }
    if (data is List && data.isNotEmpty) return '${data.first}';
    return 'Something went wrong. Please try again.';
  }

  Future<bool> _refreshAccess() {
    if (_refresh == null) return Future.value(false);
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final res = await http
          .post(_uri('/auth/token/refresh/'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh': _refresh}))
          .timeout(AppConfig.timeout);
      if (res.statusCode != 200) return false;
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      _access = d['access'] as String;
      final p = await SharedPreferences.getInstance();
      await p.setString('pfc_access', _access!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Multipart upload — used by the staff side for product photos.
  Future<dynamic> uploadFile(String path, String field, File file,
      {String method = 'PATCH', Map<String, String> fields = const {}}) async {
    final req = http.MultipartRequest(method, _uri(path))
      ..headers.addAll(_headers(json: false))
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(field, file.path));
    final streamed = await req.send().timeout(AppConfig.timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 400) throw ApiException(_readError(jsonDecode(res.body)));
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }
}
