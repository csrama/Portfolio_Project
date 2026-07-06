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

  
  Future<bool> checkLoginStatus() async {
    _accessToken = await _authService.getAccessToken();
    _refreshToken = await _authService.getRefreshToken();
    _user = await _authService.getUserData();
    _isLoggedIn = _accessToken != null;
    notifyListeners();
    return _isLoggedIn;
  }

  
  Future<bool> login(String accessToken, String refreshToken, Map<String, dynamic> user) async {
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
      return false;
    }
  }

  
  Future<void> logout() async {
    await _authService.clearTokens();
    await _authService.clearUserData();
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  
  Future<void> updateAccessToken(String newAccessToken) async {
    await _authService.saveTokens(newAccessToken, _refreshToken!);
    _accessToken = newAccessToken;
    notifyListeners();
  }
}
