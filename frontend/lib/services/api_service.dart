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
}
