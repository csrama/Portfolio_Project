import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static const _webClientId = '760699279835-8dh4u6up1b7jhrt1jblo6vopv9589767.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithBackend({required AuthService authService}) async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token');
      }

      try {
        final result = await ApiService.postJson(
          '/auth/google',
          body: {'idToken': idToken},
        );

        await authService.persistSession(
          accessToken: result['token']?.toString() ?? 'google-token',
          refreshToken: result['refreshToken']?.toString() ?? 'google-refresh-token',
          user: {
            'email': (result['user']?['email'] ?? account.email).toString().toLowerCase(),
            'full_name': (result['user']?['full_name'] ?? account.displayName ?? account.email).toString(),
            'picture': account.photoUrl,
            'provider': 'google',
          },
        );

        return {...result, 'mode': 'online'};
      } catch (e) {
        final fallbackUserName = account.displayName?.trim().isNotEmpty == true
            ? account.displayName!.trim()
            : 'Google User';
        
        await authService.persistSession(
          accessToken: 'offline-token',
          refreshToken: 'offline-refresh-token',
          user: {
            'email': 'google-user@localhost',
            'full_name': fallbackUserName,
            'user_type': 'general_user',
            'provider': 'google-offline',
          },
        );

        return {
          'user': {
            'email': 'google-user@localhost',
            'full_name': fallbackUserName,
            'user_type': 'general_user',
          },
          'token': 'offline-token',
          'refreshToken': 'offline-refresh-token',
          'mode': 'offline',
        };
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
