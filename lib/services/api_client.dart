import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resolves the marketgo-api base URL.
/// Use `--dart-define=API_URL=...` to override; otherwise the production API
/// at https://api.suftrip.com is used.
String defaultApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return 'https://api.suftrip.com';
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin JSON client for the marketgo-api (shared by auth + mover services).
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? defaultApiBaseUrl();

  final http.Client _http;
  final String baseUrl;
  Future<String> uploadProfileImage(
      List<int> bytes, String name, String token) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/uploads'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    final stream =
        await _http.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(stream)
        .timeout(const Duration(seconds: 30));
    final result = _decode(response);
    final url = result['url'];
    if (url is! String || url.isEmpty) {
      throw const ApiException('Image upload failed');
    }
    await put('/api/v1/auth/avatar',
        body: {'avatar_url': url}, headers: {'Authorization': 'Bearer $token'});
    return url;
  }

  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body, Map<String, String>? headers}) =>
      _request('POST', path, body: body, headers: headers);
  Future<Map<String, dynamic>> get(String path,
          {Map<String, String>? headers}) =>
      _request('GET', path, headers: headers);
  Future<Map<String, dynamic>> put(String path,
          {Map<String, dynamic>? body, Map<String, String>? headers}) =>
      _request('PUT', path, body: body, headers: headers);
  Future<Map<String, dynamic>> delete(String path,
          {Map<String, String>? headers}) =>
      _request('DELETE', path, headers: headers);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll({'Content-Type': 'application/json', ...?headers});
      if (body != null) request.body = jsonEncode(body);
      final stream =
          await _http.send(request).timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(stream)
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
          'The request timed out. Check your connection and try again.');
    } on http.ClientException {
      throw const ApiException(
          'Unable to connect. Check your connection and try again.');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      json = const <String, dynamic>{};
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message =
          (json['error'] as String?) ?? 'Request failed (${res.statusCode})';
      throw ApiException(message, statusCode: res.statusCode);
    }
    return json;
  }
}
