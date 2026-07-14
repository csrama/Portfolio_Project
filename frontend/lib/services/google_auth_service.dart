import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import 'api_service.dart';

class GoogleAuthService {
  

  static const String _webClientId =
      '760699279835-8dh4u6up1b7jhrt1jblo6vopv9589767.apps.googleusercontent.com';


  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint(' Google Sign-In: User cancelled');
        return null;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token');
      }

      debugPrint(' Google Sign-In: ID token received');

      try {
        final result = await ApiService.postJson(
          '/auth/google',
          body: {'idToken': idToken},
        );

        final token = result['token']?.toString();
        final refreshToken = result['refreshToken']?.toString();
        final userData = result['user'] as Map<String, dynamic>?;

        if (token == null || userData == null) {
          throw Exception('Invalid response from backend');
        }

        return {
          'token': token,
          'refreshToken': refreshToken ?? '',
          'user': userData,
          'mode': 'online',
        };
      } catch (backendError) {
        debugPrint(' Google Backend error: $backendError');

        final fallbackUserName = account.displayName?.trim().isNotEmpty == true
            ? account.displayName!.trim()
            : 'Google User';

        return {
          'token': 'offline-token',
          'refreshToken': '',
          'user': {
            'email': account.email,
            'full_name': fallbackUserName,
            'user_type': 'general_user',
            'photo_url': account.photoUrl,
          },
          'mode': 'offline',
        };
      }
    } catch (e) {
      debugPrint(' Google Sign-In Error: $e');
      return null;
    }
  }

  @Deprecated('Use signInWithGoogle() instead')
  Future<Map<String, dynamic>?> signInWithBackend({
    required AuthService authService,
  }) async {
    final result = await signInWithGoogle();
    
    if (result == null) return null;

    final token = result['token']?.toString();
    final user = result['user'] as Map<String, dynamic>?;

    if (token != null && user != null) {
      await authService.saveUserSession(
        userData: user,
        accessToken: token,
        refreshToken: result['refreshToken']?.toString() ?? '',
      );
    }

    return result;
  }

 
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint(' Google Sign-Out: Success');
    } catch (e) {
      debugPrint(' Google Sign-Out Error: $e');
    }
  }

 
  Future<bool> isSignedIn() async {
    try {
      final account = await _googleSignIn.isSignedIn();
      debugPrint(' Google Sign-In Status: $account');
      return account;
    } catch (e) {
      debugPrint(' Google Sign-In Status Error: $e');
      return false;
    }
  }

  Future<GoogleSignInAccount?> getCurrentAccount() async {
    try {
      return await _googleSignIn.currentUser;
    } catch (e) {
      debugPrint(' Get current account error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final account = await _googleSignIn.currentUser;
      if (account == null) return null;

      return {
        'id': account.id,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
      };
    } catch (e) {
      debugPrint(' Get current user data error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> reauthenticate() async {
    try {
      await _googleSignIn.signOut();

      return await signInWithGoogle();
    } catch (e) {
      debugPrint(' Re-authentication error: $e');
      return null;
    }
  }

  
  void enableDebugMode() {
    debugPrint(' GoogleAuthService: Debug mode enabled');
  }

  Future<String?> getIdToken() async {
    try {
      final account = await _googleSignIn.currentUser;
      if (account == null) return null;

      final authentication = await account.authentication;
      return authentication.idToken;
    } catch (e) {
      debugPrint(' Get ID token error: $e');
      return null;
    }
  }
}
