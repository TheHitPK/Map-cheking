import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/config.dart';
import '../strings.dart';

/// Failure with a message fit for the UI. [statusCode] is null for network errors.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  /// The server will never accept this request as is: do not retry it.
  bool get isPermanent => statusCode != null && statusCode! >= 400 && statusCode! < 500 && !const {401, 408, 429}.contains(statusCode);

  @override
  String toString() => message;
}

/// Thin JSON client. The token is read on every call so a new login takes effect immediately.
class ApiClient {
  ApiClient({required this.tokenProvider, http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        _base = baseUrl ?? AppConfig.apiUrl;

  final String? Function() tokenProvider;
  final http.Client _http;
  final String _base;

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, Object body) => _send('POST', path, body: body);

  Future<dynamic> put(String path, Object body) => _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final req = http.Request(method, uri)..headers['Accept'] = 'application/json';
    final token = tokenProvider();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(AppConfig.requestTimeout));
    } on TimeoutException {
      throw ApiException(S.serverSlow);
    } catch (_) {
      throw ApiException(S.noConnection);
    }
    final text = utf8.decode(res.bodyBytes);
    final decoded = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    throw ApiException(_message(res.statusCode, decoded), statusCode: res.statusCode);
  }

  static dynamic _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static String _message(int status, dynamic body) {
    if (body is Map && body['detail'] is String) return body['detail'] as String;
    return switch (status) {
      401 => S.sessionExpired,
      403 => S.noPermission,
      404 => S.notFound,
      429 => S.tooManyAttempts,
      >= 500 => S.serverError,
      _ => S.rejected(status),
    };
  }
}
