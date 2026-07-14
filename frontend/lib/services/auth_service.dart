import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService {

  static const _savedUserEmailKey = 'saved_user_email';
  static const _savedUserNameKey = 'saved_user_name';
  static const _savedUserPasswordKey = 'saved_user_password';
  static const _savedTokenKey = 'saved_auth_token';
  static const _savedRefreshTokenKey = 'saved_refresh_token';
  static const _savedUserDataKey = 'saved_user_data';
  static const _savedTokenExpiryKey = 'saved_token_expiry'; 

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> body)?
        onlineRequest,
  }) async {
    final requestBody = {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'user_type': 'general_user',
    };

    try {
      final result = await (onlineRequest ?? _registerOnline)(requestBody);
      await _saveSessionData(
        email: requestBody['email'] as String,
        fullName: fullName.trim(),
        password: password,
        token: result['token']?.toString(),
        refreshToken: result['refreshToken']?.toString(),
        userData: result['user'] as Map<String, dynamic>?,
      );
      return {...result, 'mode': 'online'};
    } catch (_) {
      await _saveSessionData(
        email: requestBody['email'] as String,
        fullName: fullName.trim(),
        password: password,
        token: 'offline-token',
        refreshToken: null,
        userData: {
          'email': requestBody['email'],
          'full_name': fullName.trim(),
          'user_type': 'general_user',
        },
      );
      return {
        'user': {
          'email': requestBody['email'],
          'full_name': fullName.trim(),
          'user_type': 'general_user',
        },
        'token': 'offline-token',
        'mode': 'offline',
      };
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> body)?
        onlineRequest,
  }) async {
    final requestBody = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    try {
      final result = await (onlineRequest ?? _loginOnline)(requestBody);
      await _saveSessionData(
        email: requestBody['email'] as String,
        fullName: result['user']?['full_name']?.toString() ?? email.trim(),
        password: password,
        token: result['token']?.toString(),
        refreshToken: result['refreshToken']?.toString(),
        userData: result['user'] as Map<String, dynamic>?,
      );
      return {...result, 'mode': 'online'};
    } catch (_) {
      final storedUser = await _loadStoredUser();
      if (storedUser != null &&
          storedUser['email'] == requestBody['email'] &&
          storedUser['password'] == password) {
        return {
          'user': {
            'email': storedUser['email'],
            'full_name': storedUser['full_name'],
            'user_type': 'general_user',
          },
          'token': 'offline-token',
          'mode': 'offline',
        };
      }
      throw Exception('Unable to sign in offline');
    }
  }


  Future<Map<String, dynamic>> _registerOnline(
      Map<String, dynamic> body) async {
    return ApiService.postJson('/auth/register', body: body);
  }

  Future<Map<String, dynamic>> _loginOnline(Map<String, dynamic> body) async {
    return ApiService.postJson('/auth/login', body: body);
  }

  Future<void> _saveSessionData({
    required String email,
    required String fullName,
    required String password,
    String? token,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_savedUserEmailKey, email.toLowerCase());
    await prefs.setString(_savedUserNameKey, fullName.trim());
    await prefs.setString(_savedUserPasswordKey, password);
    
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_savedTokenKey, token);
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(_savedRefreshTokenKey, refreshToken);
      }
      
      try {
        final expiry = _extractTokenExpiry(token);
        if (expiry != null) {
          await prefs.setString(_savedTokenExpiryKey, expiry.toIso8601String());
        }
      } catch (e) {
      }
    }
    
    if (userData != null) {
      await prefs.setString(_savedUserDataKey, jsonEncode(userData));
    }
  }

  DateTime? _extractTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      final expiry = payload['exp'];
      if (expiry != null) {
        return DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedTokenKey);
  }

  Future<String?> getAccessToken() async {
    return await getToken();
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedRefreshTokenKey);
  }

  Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_savedTokenExpiryKey);
    if (expiryStr != null) {
      try {
        return DateTime.parse(expiryStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<String?> getStoredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedUserNameKey);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(_savedUserDataKey);
    if (userDataJson != null && userDataJson.isNotEmpty) {
      try {
        return jsonDecode(userDataJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedTokenKey, accessToken);
    await prefs.setString(_savedRefreshTokenKey, refreshToken);
    
    final expiry = _extractTokenExpiry(accessToken);
    if (expiry != null) {
      await prefs.setString(_savedTokenExpiryKey, expiry.toIso8601String());
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUserDataKey, jsonEncode(userData));
  }

  Future<void> saveUserSession({
    required Map<String, dynamic> userData,
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveTokens(accessToken, refreshToken);
    await saveUserData(userData);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTokenKey);
    await prefs.remove(_savedRefreshTokenKey);
    await prefs.remove(_savedTokenExpiryKey);
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUserDataKey);
  }

  Future<void> clearUserSession() async {
    await clearTokens();
    await clearUserData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUserEmailKey);
    await prefs.remove(_savedUserNameKey);
    await prefs.remove(_savedUserPasswordKey);
  }

  Future<void> logout() async {
    await clearUserSession();
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty && token != 'offline-token') {
      return true;
    }

    final storedUser = await _loadStoredUser();
    return storedUser != null && 
           storedUser['email'] != null && 
           storedUser['full_name'] != null;
  }

  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty || token == 'offline-token') {
      return false;
    }

    final expiry = await getTokenExpiry();
    if (expiry != null) {
      final now = DateTime.now();
      if (now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        return false; 
      }
    }

    return true;
  }

  Future<bool> needsRefresh() async {
    final isValid = await isTokenValid();
    return !isValid;
  }

  Future<String> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await ApiService.postJson(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

      final newAccessToken = response['accessToken']?.toString();
      final newRefreshToken = response['refreshToken']?.toString();

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await saveTokens(newAccessToken, newRefreshToken ?? refreshToken);
        return newAccessToken;
      } else {
        throw Exception('Invalid response from refresh endpoint');
      }
    } catch (e) {
      await clearTokens();
      throw Exception('Failed to refresh token: $e');
    }
  }

  Future<String?> getValidToken() async {
    if (await isTokenValid()) {
      return await getAccessToken();
    }
    
    if (await needsRefresh()) {
      try {
        return await refreshAccessToken();
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }


  Future<Map<String, String>?> _loadStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_savedUserEmailKey);
    final fullName = prefs.getString(_savedUserNameKey);
    final password = prefs.getString(_savedUserPasswordKey);

    if (email == null || fullName == null || password == null) {
      return null;
    }

    return {
      'email': email,
      'full_name': fullName,
      'password': password,
    };
  }

  Future<bool> isOnlineMode() async {
    final token = await getToken();
    return token != null && token.isNotEmpty && token != 'offline-token';
  }

  Map<String, dynamic>? decodeToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      return payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
