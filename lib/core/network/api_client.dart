import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client;
  String? firebaseToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (firebaseToken != null) {
      headers['Authorization'] = 'Bearer $firebaseToken';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    Uri uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    if (queryParameters != null) {
      final Map<String, String> stringParams = {};
      queryParameters.forEach((key, value) {
        stringParams[key] = value.toString();
      });
      uri = uri.replace(queryParameters: stringParams);
    }
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    var uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    if (queryParameters != null) {
      final stringParams = <String, String>{};
      queryParameters.forEach((key, value) {
        stringParams[key] = value.toString();
      });
      uri = uri.replace(queryParameters: stringParams);
    }
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    var uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    if (queryParameters != null) {
      final stringParams = <String, String>{};
      queryParameters.forEach((key, value) {
        stringParams[key] = value.toString();
      });
      uri = uri.replace(queryParameters: stringParams);
    }
    final request = http.Request('DELETE', uri);
    request.headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}
