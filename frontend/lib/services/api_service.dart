import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'https://portfolioproject-production-2b3b.up.railway.app';
    } else {
      // للـ Android (محاكي)
      return 'https://portfolioproject-production-2b3b.up.railway.app';
    }
  }


  static String buildUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$_baseUrl$path';
  }

  static Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = buildUrl(path);
    print('PUT: $url');
    print('Body: $body');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = buildUrl(path);
    print('PATCH: $url');
    print('Body: $body');

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = buildUrl(path);
    print('POST: $url');
    print('Body: $body');
    
    if (token != null && token.length > 20) {
      print('Token: Bearer ${token.substring(0, 20)}...');
    } else if (token != null) {
      print('Token: Bearer $token');
    } else {
      print('Token: No token');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<dynamic> getJsonDynamic(
  String path, {
  String? token,
}) async {
  final url = buildUrl(path);
  print('GET: $url');

  final response = await http.get(
    Uri.parse(url),
    headers: {if (token != null) 'Authorization': 'Bearer $token'},
  );

  print('Status: ${response.statusCode}');
  print('Response: ${response.body}');

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  throw Exception('Request failed: ${response.statusCode} ${response.body}');
}

  static Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? token,
  }) async {
    final url = buildUrl(path);
    print('DELETE: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    print('Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  static Future<List<dynamic>> getJsonList(
    String path, {
    String? token,
  }) async {
    final url = buildUrl(path);
    print('GET LIST: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    print('Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(response.body);
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
    final url = buildUrl(path);
    print('POST LIST: $url');
    print('Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');

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

  static Future<void> delete(
    String path, {
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final url = buildUrl(path);
    print('DELETE: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    print('Status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE failed: ${response.statusCode} ${response.body}');
    }
  }
}