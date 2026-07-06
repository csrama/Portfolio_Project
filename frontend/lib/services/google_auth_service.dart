import 'package:google_sign_in/google_sign_in.dart';

// IMPORTANT: For Google Sign-In to work on Flutter Web, you must add
// http://localhost:47071 as an Authorized JavaScript Origin in Google Console:
// https://console.cloud.google.com/apis/credentials
// Under the OAuth 2.0 Client ID:
// 760699279835-8dh4u6up1b7jhrt1jblo6vopv9589767.apps.googleusercontent.com

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "760699279835-8dh4u6up1b7jhrt1jblo6vopv9589767.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Sign out first to always show the account picker
      await _googleSignIn.signOut();
      return await _googleSignIn.signIn();
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
