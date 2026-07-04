import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: "760699279835-8dh4u6up1b7jhrt1jblo6vopv9589767.apps.googleusercontent.com",
);

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}
