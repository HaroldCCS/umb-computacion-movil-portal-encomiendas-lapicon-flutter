import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'app_exception.dart';

/// Devuelve el idToken de Firebase del usuario actual (o null si no hay sesión).
typedef TokenProvider = Future<String?> Function({bool forceRefresh});

/// Cliente HTTP único para el backend de Lapticon.
///
/// - Agrega `Authorization: Bearer <idToken>` a las rutas protegidas.
/// - Si el backend responde 401, refresca el token y reintenta una vez.
/// - Convierte los errores en [AppException] con mensajes en español.
/// - Expone [serverWaking] para avisar cuando el servidor está "despertando".
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenProvider tokenProvider,
    http.Client? httpClient,
    this.timeout = Env.requestTimeout,
    this.slowThreshold = Env.slowRequestThreshold,
  }) : _tokenProvider = tokenProvider,
       _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final Duration slowThreshold;
  final TokenProvider _tokenProvider;
  final http.Client _http;

  /// `true` mientras haya una petición tardando más de [slowThreshold].
  final ValueNotifier<bool> serverWaking = ValueNotifier<bool>(false);
  int _slowRequests = 0;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required bool auth,
  }) async {
    var response = await _request(method, path, query, body, auth, false);
    if (auth && response.statusCode == 401) {
      // El token pudo expirar justo ahora: se pide uno nuevo y se reintenta.
      response = await _request(method, path, query, body, auth, true);
    }
    return _handle(response);
  }

  Future<http.Response> _request(
    String method,
    String path,
    Map<String, String>? query,
    Object? body,
    bool auth,
    bool forceRefresh,
  ) async {
    final uri = buildUri(path, query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await _tokenProvider(forceRefresh: forceRefresh);
      if (token == null) throw const NotAuthenticatedException();
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    var isSlow = false;
    final slowTimer = Timer(slowThreshold, () {
      isSlow = true;
      _markSlow();
    });

    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } finally {
      slowTimer.cancel();
      if (isSlow) _unmarkSlow();
    }
  }

  void _markSlow() {
    _slowRequests++;
    serverWaking.value = true;
  }

  void _unmarkSlow() {
    if (_slowRequests > 0) _slowRequests--;
    if (_slowRequests == 0) serverWaking.value = false;
  }

  @visibleForTesting
  Uri buildUri(String path, Map<String, String>? query) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$base$path');
    return (query == null || query.isEmpty)
        ? uri
        : uri.replace(queryParameters: query);
  }

  dynamic _handle(http.Response response) {
    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException(
      response.statusCode,
      extractMessage(decoded) ??
          ApiException.defaultMessage(response.statusCode),
    );
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  /// Busca un mensaje legible en las formas típicas de error de Express.
  @visibleForTesting
  static String? extractMessage(dynamic body) {
    if (body is String && body.isNotEmpty && body.length < 200) {
      // Evita mostrar páginas HTML de error.
      return body.startsWith('<') ? null : body;
    }
    if (body is Map) {
      for (final key in const [
        'message',
        'mensaje',
        'error',
        'msg',
        'detail',
      ]) {
        final value = body[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is Map) {
          final nested = extractMessage(value);
          if (nested != null) return nested;
        }
      }
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String) return first;
        if (first is Map) return extractMessage(first);
      }
    }
    return null;
  }

  void dispose() {
    _http.close();
    serverWaking.dispose();
  }
}
