import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ApiService {
  static String get _baseUrl => Environment.baseUrl;

  static String buildUrl(String path) {
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$_baseUrl$cleanPath';
  }

  static Map<String, String> _buildHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response: ${response.body}');
      }
    }

    String errorMessage;
    try {
      final errorBody = jsonDecode(response.body);
      errorMessage = errorBody['message'] ?? errorBody['error'] ?? response.body;
    } catch (e) {
      errorMessage = response.body;
    }

    throw Exception('API Error [${response.statusCode}]: $errorMessage');
  }

  // ---------- GET ----------
  static Future<dynamic> getJsonDynamic(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getJsonList(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
    );
    final decoded = _handleResponse(response);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final list = decoded['data'] ?? decoded['items'] ?? decoded['results'];
      if (list is List) return list;
    }
    throw Exception('Expected a JSON array but got: $decoded');
  }

  static Future<Map<String, dynamic>> getJsonMap(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
    );
    final decoded = _handleResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }

  // ---------- POST ----------
  static Future<dynamic> postJsonDynamic(String path,
      {required Map<String, dynamic> body, String? token}) async {
    final response = await http.post(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postJson(String path,
      {required Map<String, dynamic> body, String? token}) async {
    final response = await http.post(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
      body: jsonEncode(body),
    );
    final decoded = _handleResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }

  static Future<List<dynamic>> postJsonList(String path,
      {required Map<String, dynamic> body, String? token}) async {
    final response = await http.post(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
      body: jsonEncode(body),
    );
    final decoded = _handleResponse(response);
    if (decoded is List) return decoded;
    throw Exception('Expected a JSON array but got: $decoded');
  }

  // ---------- PUT ----------
  static Future<Map<String, dynamic>> putJson(String path,
      {required Map<String, dynamic> body, String? token}) async {
    final response = await http.put(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
      body: jsonEncode(body),
    );
    final decoded = _handleResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }

  // ---------- PATCH ----------
  static Future<Map<String, dynamic>> patchJson(String path,
      {required Map<String, dynamic> body, String? token}) async {
    final response = await http.patch(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
      body: jsonEncode(body),
    );
    final decoded = _handleResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }

  // ---------- DELETE ----------
  static Future<bool> deleteJson(String path, {String? token}) async {
    final response = await http.delete(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return true;
    String errorMessage;
    try {
      final errorBody = jsonDecode(response.body);
      errorMessage = errorBody['message'] ?? errorBody['error'] ?? response.body;
    } catch (e) {
      errorMessage = response.body;
    }
    throw Exception('Delete failed [${response.statusCode}]: $errorMessage');
  }

  static Future<Map<String, dynamic>> deleteJsonWithData(String path,
      {String? token}) async {
    final response = await http.delete(
      Uri.parse(buildUrl(path)),
      headers: _buildHeaders(token: token),
    );
    final decoded = _handleResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }
}
