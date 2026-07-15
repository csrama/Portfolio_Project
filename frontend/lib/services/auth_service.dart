import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart'; 

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _userNameKey = 'user_name';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  
  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(user));
    if (user['full_name'] != null) {
      await _storage.write(key: _userNameKey, value: user['full_name'].toString());
    }
  }

  
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  
  Future<String?> getStoredUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  
  Future<void> persistSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await saveTokens(accessToken, refreshToken);
    await saveUserData(user);
  }

  
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _userNameKey);
  }

  
  Future<void> clearUserData() async {
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _userNameKey);
  }

  
  Future<void> updateAccessToken(String newAccessToken) async {
    await _storage.write(key: _accessTokenKey, value: newAccessToken);
  }

  
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        await updateAccessToken(newAccessToken);
        return newAccessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    // For backward-compat usage in other services/tests.
    return await getAccessToken();
  }

  /// Signs up the user.
  ///
  /// If the online request fails, falls back to an offline mode.
  /// This is used by the existing unit tests.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) onlineRequest,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
    };

    try {
      final result = await onlineRequest(payload);
      final token = result['token']?.toString();
      final user = result['user'] as Map<String, dynamic>?;
      final refreshToken = result['refreshToken']?.toString() ?? '';

      if (token != null && user != null) {
        await persistSession(
          accessToken: token,
          refreshToken: refreshToken,
          user: user,
        );
      }

      return {
        'mode': 'online',
        'token': token,
        'refreshToken': refreshToken,
        'user': user ?? payload,
      };
    } catch (_) {
      await persistSession(
        accessToken: 'offline-token',
        refreshToken: 'offline-refresh-token',
        user: {
          'email': email,
          'full_name': fullName,
        },
      );

      return {
        'mode': 'offline',
        'token': 'offline-token',
        'refreshToken': 'offline-refresh-token',
        'user': {
          'email': email,
          'full_name': fullName,
        },
      };
    }
  }

  /// Calls backend /auth/login and persists session tokens + user.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/auth/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token']?.toString();
    final refreshToken = response.data['refreshToken']?.toString() ?? '';
    final user = response.data['user'] as Map<String, dynamic>?;

    if (token == null || user == null) {
      throw Exception('Login failed: missing token/user');
    }

    await persistSession(
      accessToken: token,
      refreshToken: refreshToken,
      user: user,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Calls backend /auth/register and persists session tokens + user.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? userType,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (userType != null) 'user_type': userType,
      },
    );

    final token = response.data['token']?.toString();
    final refreshToken = response.data['refreshToken']?.toString() ?? '';
    final user = response.data['user'] as Map<String, dynamic>?;

    if (token == null || user == null) {
      throw Exception('Register failed: missing token/user');
    }

    await persistSession(
      accessToken: token,
      refreshToken: refreshToken,
      user: user,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Server-side logout.
  ///
  /// Note: backend must implement POST /auth/logout for DB-backed invalidation.
  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      final refreshToken = await getRefreshToken();

      // If backend supports refresh-token logout, call it.
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          '${ApiConfig.baseUrl}/auth/logout',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          }),
        );
      }
    } catch (_) {
      // Even if server logout fails, clear local session so UI logs out.
    }

    await clearTokens();
    await clearUserData();
  }
}
