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
  bool _isInitialized = false;

  

  AuthProvider({required AuthService authService})
      : _authService = authService;

  
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;  
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get hasValidSession => _isAuthenticated && _accessToken != null;
  String get userName => _currentUser?.fullName ?? 'مستخدم';
  bool get isCaregiver => _currentUser?.userType == 'caregiver';
  bool get isPatient => _currentUser?.userType == 'general_user';

 
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final hasSession = await _authService.hasSession();
      
      if (hasSession) {
        await restoreSession();
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        _accessToken = null;
      }

      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restoreSession() async {
    try {
      final token = await _authService.getAccessToken();
      final userData = await _authService.getUserData();

      if (token != null && token.isNotEmpty && token != 'offline-token') {
        _accessToken = token;
        _refreshToken = await _authService.getRefreshToken();
        _isAuthenticated = true;

        if (userData != null) {
          _currentUser = User.fromJson(userData);
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> checkSession() async {
    final hasSession = await _authService.hasSession();
    if (!hasSession) {
      _isAuthenticated = false;
      _currentUser = null;
      _accessToken = null;
      notifyListeners();
      return false;
    }

    return restoreSession();
  }

 
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
        final token = result['token'].toString();
        final refreshToken = result['refreshToken']?.toString();
        final userData = result['user'] as Map<String, dynamic>?;

        if (userData == null) {
          throw Exception('بيانات المستخدم غير مكتملة');
        }

        await _authService.saveTokens(
          token,
          refreshToken ?? '',
        );
        await _authService.saveUserData(userData);

        _accessToken = token;
        _refreshToken = refreshToken;
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
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

  Future<bool> loginWithData({
    required String token,
    required Map<String, dynamic> userData,
    String? refreshToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.saveTokens(
        token,
        refreshToken ?? '',
      );
      await _authService.saveUserData(userData);

      _accessToken = token;
      _refreshToken = refreshToken;
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
      _errorMessage = null;

      notifyListeners();
      return true;
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
    String userType = 'general_user',
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
        final token = result['token'].toString();
        final refreshToken = result['refreshToken']?.toString();
        final userData = result['user'] as Map<String, dynamic>?;

        if (userData == null) {
          throw Exception('بيانات المستخدم غير مكتملة');
        }

        await _authService.saveTokens(
          token,
          refreshToken ?? '',
        );
        await _authService.saveUserData(userData);

        _accessToken = token;
        _refreshToken = refreshToken;
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
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

 
  Future<bool> refreshAccessToken() async {  
    if (_refreshToken == null) {
      _errorMessage = 'No refresh token available';
      notifyListeners();
      return false;
    }

    try {
      final newToken = await _authService.refreshAccessToken();
      if (newToken.isNotEmpty) {
        _accessToken = newToken;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> getValidToken() async {
    if (_accessToken == null) return null;

    final isValid = await _authService.isTokenValid();
    if (!isValid) {
      final success = await refreshAccessToken();    
      if (!success) {
        await logout();
        return null;
      }
    }

    return _accessToken;
  }


  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();

      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logoutAndClear() async {
    await _authService.clearUserSession();
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  
  void clear() {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _isLoading = false;
    _isAuthenticated = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

 

  Future<bool> isTokenValid() async {
    return await _authService.isTokenValid();
  }

  Future<bool> needsRefresh() async {
    return await _authService.needsRefresh();
  }

  Future<bool> isOfflineMode() async {
    return await _authService.isOnlineMode();
  }

  Future<void> updateUserData(Map<String, dynamic> newData) async {
    if (_currentUser == null) return;

    try {
      await _authService.saveUserData(newData);
      _currentUser = User.fromJson(newData);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String? get token => _accessToken;
  bool get hasValidToken => _accessToken != null && _accessToken!.isNotEmpty;
}
