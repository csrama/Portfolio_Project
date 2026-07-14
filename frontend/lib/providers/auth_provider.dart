import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  AuthProvider({required AuthService authService}) : _authService = authService;

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result['token'] != null) {
        _accessToken = result['token'].toString();
        _refreshToken = result['refreshToken']?.toString();
        _isAuthenticated = true;
        
        final userData = result['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = User.fromJson(userData);
        }
        
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (result['token'] != null) {
        _accessToken = result['token'].toString();
        _refreshToken = result['refreshToken']?.toString();
        _isAuthenticated = true;
        
        final userData = result['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = User.fromJson(userData);
        }
        
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    final hasSession = await _authService.hasSession();
    if (!hasSession) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }

    final token = await _authService.getAccessToken();
    if (token != null) {
      _accessToken = token;
      _isAuthenticated = true;
      
      final userData = await _authService.getUserData();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
      
      notifyListeners();
      return true;
    }

    return false;
  }


  void clear() {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _isLoading = false;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }
}
