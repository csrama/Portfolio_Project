import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static const _savedUserEmailKey = 'saved_user_email';
  static const _savedUserNameKey = 'saved_user_name';
  static const _savedUserPasswordKey = 'saved_user_password';
  static const _savedTokenKey = 'saved_auth_token';

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
    return storedUser != null && storedUser['email'] != null && storedUser['full_name'] != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTokenKey);
    await prefs.remove(_savedUserEmailKey);
    await prefs.remove(_savedUserNameKey);
    await prefs.remove(_savedUserPasswordKey);
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
}
