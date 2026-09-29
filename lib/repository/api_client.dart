import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown when a request fails. [message] is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.isOffline = false});

  /// HTTP status code, or 0 when there was no response (offline, timeout).
  final int statusCode;
  final String message;

  /// True when the server couldn't be reached at all.
  final bool isOffline;

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// A small wrapper around `package:http` that sends and receives JSON.
/// You don't need to read this file to follow the chatbot flow.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(Uri url, {String? token}) {
    return _send(() => _client.get(url, headers: _headers(token)));
  }

  Future<dynamic> post(Uri url, {String? token, Object? body}) {
    return _send(
      () => _client.post(
        url,
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw ApiException(0, 'No internet connection.', isOffline: true);
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to respond.');
    } on http.ClientException catch (e) {
      throw ApiException(0, e.message, isOffline: true);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(response));
    }
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(response.statusCode, 'Unexpected response.');
    }
  }

  /// Direct Line errors look like `{"error": {"code": "...", "message": "..."}}`.
  static String _errorMessage(http.Response response) {
    try {
      final error = jsonDecode(response.body)['error'];
      final message = error is Map ? error['message'] : error;
      if (message != null) return '$message (HTTP ${response.statusCode})';
    } catch (_) {}
    return 'Request failed (HTTP ${response.statusCode}).';
  }
}
