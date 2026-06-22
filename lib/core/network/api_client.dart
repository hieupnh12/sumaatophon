import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

/// Client HTTP dùng chung cho mọi feature gọi backend.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
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
