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
      await persistSession(
        email: requestBody['email'] as String,
        fullName: fullName.trim(),
        password: password,
        token: result['token']?.toString(),
      );
      return {...result, 'mode': 'online'};
    } catch (_) {
      await persistSession(
        email: requestBody['email'] as String,
        fullName: fullName.trim(),
        password: password,
        token: 'offline-token',
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
      await persistSession(
        email: requestBody['email'] as String,
        fullName: result['user']?['full_name']?.toString() ?? email.trim(),
        password: password,
        token: result['token']?.toString(),
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedTokenKey);
  }

  Future<String?> getStoredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedUserNameKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      return true;
    }

    final storedUser = await _loadStoredUser();
    return storedUser != null && 
           storedUser['email'] != null && 
           storedUser['full_name'] != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTokenKey);
    await prefs.remove(_savedRefreshTokenKey);
    await prefs.remove(_savedUserEmailKey);
    await prefs.remove(_savedUserNameKey);
    await prefs.remove(_savedUserPasswordKey);
    await prefs.remove(_savedUserDataKey);
  }

  Future<void> persistSession({
    required String email,
    required String fullName,
    required String password,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUserEmailKey, email.toLowerCase());
    await prefs.setString(_savedUserNameKey, fullName.trim());
    await prefs.setString(_savedUserPasswordKey, password);
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_savedTokenKey, token);
    } else {
      await prefs.setString(_savedTokenKey, 'offline-token');
    }
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


  // جلب توكن الوصول (Access Token)
  Future<String?> getAccessToken() async {
    return await getToken(); // reuse existing method
  }

  // جلب توكن التحديث (Refresh Token)
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedRefreshTokenKey);
  }

  // حفظ التوكنات (Access + Refresh)
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedTokenKey, accessToken);
    await prefs.setString(_savedRefreshTokenKey, refreshToken);
  }

  // مسح جميع التوكنات
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTokenKey);
    await prefs.remove(_savedRefreshTokenKey);
  }

  // جلب بيانات المستخدم المخزنة
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

  // حفظ بيانات المستخدم
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUserDataKey, jsonEncode(userData));
  }

  // مسح بيانات المستخدم
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUserDataKey);
  }

  // تجديد توكن الوصول باستخدام Refresh Token
  Future<String> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    try {
      // استدعاء API لتجديد التوكن
      final response = await ApiService.postJson(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

      final newAccessToken = response['accessToken']?.toString();
      final newRefreshToken = response['refreshToken']?.toString();

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        // حفظ التوكنات الجديدة
        await saveTokens(newAccessToken, newRefreshToken ?? refreshToken);
        return newAccessToken;
      } else {
        throw Exception('Invalid response from refresh endpoint');
      }
    } catch (e) {
      // إذا فشل التجديد، امسح التوكنات وأعد طرح الاستثناء
      await clearTokens();
      throw Exception('Failed to refresh token: $e');
    }
  }

  // حفظ بيانات المستخدم والتوكنات معاً (للاستخدام السهل)
  Future<void> saveUserSession({
    required Map<String, dynamic> userData,
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveTokens(accessToken, refreshToken);
    await saveUserData(userData);
  }

  // مسح جلسة المستخدم بالكامل
  Future<void> clearUserSession() async {
    await clearTokens();
    await clearUserData();
  }

  // التحقق من صلاحية التوكن (اختياري)
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return true;
  }
}
