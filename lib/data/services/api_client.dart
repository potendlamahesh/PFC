import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants.dart';
import 'token_store.dart';

/// Thrown for every failed request. [message] is already user-readable —
/// it carries whatever `detail` the Django view returned.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic> fieldErrors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 400;
  bool get isOffline => statusCode == null;

  @override
  String toString() => message;
}

/// One Dio instance for the whole app.
///
/// It does three jobs:
///  1. Puts `Authorization: Bearer <access>` on every request.
///  2. On a 401, calls /auth/refresh/ once and replays the request.
///  3. Turns DRF error bodies into a plain [ApiException] message.
class ApiClient {
  final TokenStore tokens;
  late final Dio _dio;

  /// Called when the refresh token is also dead — the app should log out.
  void Function()? onSessionExpired;

  bool _refreshing = false;
  Completer<bool>? _refreshWaiter;

  ApiClient(this.tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 25),
        headers: {'Accept': 'application/json'},
        // We handle every status ourselves so Dio never throws for 4xx.
        validateStatus: (_) => true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = tokens.access;
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ---------------------------------------------------------------- verbs

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query), path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body), path);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body), path);

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body), path);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete(path, data: body), path);

  // ------------------------------------------------------------- internals

  Future<dynamic> _send(
    Future<Response> Function() call,
    String path, {
    bool allowRetry = true,
  }) async {
    late Response res;
    try {
      res = await call();
    } on DioException catch (e) {
      throw ApiException(_networkMessage(e));
    }

    final code = res.statusCode ?? 0;

    if (code >= 200 && code < 300) return res.data;

    // Access token expired -> refresh once, then replay the same request.
    if (code == 401 && allowRetry && !path.contains('/auth/')) {
      final ok = await _refreshAccessToken();
      if (ok) return _send(call, path, allowRetry: false);
      onSessionExpired?.call();
      throw const ApiException(
        'Your session expired. Please log in again.',
        statusCode: 401,
      );
    }

    throw _toException(res);
  }

  /// Refreshes the access token. Concurrent callers all wait on the same call.
  Future<bool> _refreshAccessToken() async {
    if (_refreshing) return _refreshWaiter?.future ?? Future.value(false);

    final refresh = tokens.refresh;
    if (refresh == null || refresh.isEmpty) return false;

    _refreshing = true;
    _refreshWaiter = Completer<bool>();

    try {
      final res = await _dio.post(
        Api.refresh,
        data: {'refresh': refresh},
        options: Options(headers: {'Authorization': null}),
      );
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300 && res.data is Map) {
        final access = (res.data['access'] ?? '').toString();
        if (access.isNotEmpty) {
          await tokens.saveAccess(access);
          _refreshWaiter!.complete(true);
          return true;
        }
      }
      await tokens.clear();
      _refreshWaiter!.complete(false);
      return false;
    } catch (_) {
      _refreshWaiter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
    }
  }

  ApiException _toException(Response res) {
    final code = res.statusCode;
    final data = res.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // DRF's usual single-message shapes.
      for (final key in ['detail', 'message', 'error', 'non_field_errors']) {
        final v = map[key];
        if (v is String && v.isNotEmpty) {
          return ApiException(v, statusCode: code, fieldErrors: map);
        }
        if (v is List && v.isNotEmpty) {
          return ApiException(
            v.first.toString(),
            statusCode: code,
            fieldErrors: map,
          );
        }
      }

      // Per-field validation: show the first one so the user sees something real.
      for (final entry in map.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) {
          return ApiException(
            '${_humanField(entry.key)}: ${v.first}',
            statusCode: code,
            fieldErrors: map,
          );
        }
        if (v is String && v.isNotEmpty) {
          return ApiException(
            '${_humanField(entry.key)}: $v',
            statusCode: code,
            fieldErrors: map,
          );
        }
      }
    }

    return ApiException(_statusMessage(code), statusCode: code);
  }

  static String _humanField(String key) {
    final s = key.replaceAll('_', ' ');
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  static String _statusMessage(int? code) {
    switch (code) {
      case 400:
        return 'Something in that request was not right.';
      case 401:
        return 'Please log in to continue.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'We could not find that.';
      case 429:
        return 'Too many attempts. Please wait a moment.';
      case 500:
      case 502:
      case 503:
        return 'Our kitchen servers are busy. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out. Check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Could not reach the server. Please try again.';
    }
  }
}
