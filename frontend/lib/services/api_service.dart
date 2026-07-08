import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://10.0.2.2:3000';
  }

  static String buildUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$_baseUrl$path';
  }

  // ---------- existing Map-returning methods (unchanged behavior) ----------

  static Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(buildUrl(path)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(buildUrl(path)),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  // ---------- NEW: list-returning variants ----------
  // Use these for any endpoint whose JSON response is a raw array,
  // e.g. GET /dependents  ->  [ {...}, {...} ]
  // or   GET /dependents/:id/medications  ->  [ {...}, {...} ]

  static Future<List<dynamic>> getJsonList(
    String path, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse(buildUrl(path)),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(response.body);
      // Defensive: some endpoints might wrap the array as { data: [...] }
      // or { medications: [...] } — handle both shapes gracefully instead
      // of crashing.
      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map<String, dynamic>) {
        final firstListValue = decoded.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (firstListValue is List) return firstListValue;
      }
      throw Exception('Expected a JSON array from $path but got: $decoded');
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<List<dynamic>> postJsonList(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(buildUrl(path)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      throw Exception('Expected a JSON array from $path but got: $decoded');
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }
}
