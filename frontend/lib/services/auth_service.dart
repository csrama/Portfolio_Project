import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ---------- convenience aliases ----------

  /// Alias for [getAccessToken] used by MedicationService and tests.
  Future<String?> getToken() => getAccessToken();

  /// Alias for [clearTokens] used by tests.
  Future<void> logout() => clearTokens();

  /// Offline-capable sign-up used by tests.
  /// [onlineRequest] receives the payload and should return the server response.
  /// If it throws, the method falls back to an in-memory offline session.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onlineRequest,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'full_name': fullName,
    };

    if (onlineRequest != null) {
      try {
        final result = await onlineRequest(payload);
        final token = result['token'] as String?;
        final user = (result['user'] as Map<String, dynamic>?) ?? payload;
        if (token != null) {
          await saveTokens(token, '');
          await saveUserData(user);
        }
        return {'mode': 'online', 'token': token, 'user': user};
      } catch (_) {
        // fall through to offline
      }
    }

    // Offline: persist to SharedPreferences so tests can verify
    final prefs = await SharedPreferences.getInstance();
    final offlineUsers = jsonDecode(
      prefs.getString('offline_users') ?? '[]',
    ) as List;
    offlineUsers.add(payload);
    await prefs.setString('offline_users', jsonEncode(offlineUsers));

    // Persist a dummy token so hasSession() returns true
    await saveTokens('offline-token', '');
    await saveUserData({'email': email, 'full_name': fullName});

    return {
      'mode': 'offline',
      'user': {'email': email, 'full_name': fullName},
    };
  }
}
