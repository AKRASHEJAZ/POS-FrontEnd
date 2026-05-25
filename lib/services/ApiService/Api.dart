import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_end/services/ApiService/api_result.dart';
import 'package:web_end/services/storage/token_storage.dart';

enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
}

class ApiService {

  static Future<Map<String, String>> _resolveHeaders({
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    final resolved = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (authenticated) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        resolved['Authorization'] = 'Bearer $token';
      }
    }

    return resolved;
  }

  static Future<dynamic> request({
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final resolvedHeaders = await _resolveHeaders(
        headers: headers,
        authenticated: authenticated,
      );

      http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: resolvedHeaders);
          break;

        case HttpMethod.post:
          response = await http.post(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;

        case HttpMethod.put:
          response = await http.put(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;

        case HttpMethod.delete:
          response = await http.delete(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;

        case HttpMethod.patch:
          response = await http.patch(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  static Future<ApiResult> requestWithStatus({
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    try {
      final uri = Uri.parse(endpoint);
      final resolvedHeaders = await _resolveHeaders(
        headers: headers,
        authenticated: authenticated,
      );

      http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: resolvedHeaders);
          break;
        case HttpMethod.post:
          response = await http.post(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.put:
          response = await http.put(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case HttpMethod.delete:
          response = await http.delete(uri, headers: resolvedHeaders);
          break;
        case HttpMethod.patch:
          response = await http.patch(
            uri,
            headers: resolvedHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
      }

      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          // Catalog APIs may return a plain-text message body.
          decoded = response.body;
        }
      }

      return ApiResult(statusCode: response.statusCode, body: decoded);
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}