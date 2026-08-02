import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'auth_user_name';
  static const _photoUrlKey = 'auth_photo_url';
  static const _providerKey = 'auth_provider';

  Future<void> saveSession({
    String? token,
    String? userName,
    String? photoUrl,
    required String provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    }
    if (photoUrl != null) {
      await prefs.setString(_photoUrlKey, photoUrl);
    }
    await prefs.setString(_providerKey, provider);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoUrlKey);
  }

  Future<String?> getProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey) || prefs.containsKey(_providerKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_photoUrlKey);
    await prefs.remove(_providerKey);
  }
}
