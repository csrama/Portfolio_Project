import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  AuthProvider({required AuthService authService}) : _authService = authService;

  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;

  /// Reads the current session. Wrapped in try/catch + timeout because
  /// flutter_secure_storage can hang or throw on Flutter Web where the
  /// underlying platform channels are not fully implemented.
  Future<bool> checkLoginStatus() async {
    try {
      _accessToken = await _authService
          .getAccessToken()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      _refreshToken = await _authService
          .getRefreshToken()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      _user = await _authService
          .getUserData()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      _isLoggedIn = _accessToken != null;
    } catch (e) {
      // On web / unsupported platforms, treat as logged out instead of hanging.
      if (kDebugMode) {
        debugPrint('checkLoginStatus failed: $e');
      }
      _accessToken = null;
      _refreshToken = null;
      _user = null;
      _isLoggedIn = false;
    }
    notifyListeners();
    return _isLoggedIn;
  }

  Future<bool> login(String accessToken, String refreshToken,
      Map<String, dynamic> user) async {
    try {
      await _authService.saveTokens(accessToken, refreshToken);
      await _authService.saveUserData(user);
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _user = user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      // Even if secure storage fails on web, still mark the session as
      // logged-in in memory so the user can use the app.
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _user = user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Fallback: always clear local state.
      await _authService.clearTokens();
      await _authService.clearUserData();
    }
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    try {
      await _authService.saveTokens(newAccessToken, _refreshToken ?? '');
    } catch (_) {}
    _accessToken = newAccessToken;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? photoUrl,
  }) async {
    final updatedUser = Map<String, dynamic>.from(_user ?? {});
    updatedUser['full_name'] = fullName;
    updatedUser['name'] = fullName;
    updatedUser['email'] = email;
    if (photoUrl != null) {
      updatedUser['photo'] = photoUrl;
    }
    await _authService.saveUserData(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }
}
