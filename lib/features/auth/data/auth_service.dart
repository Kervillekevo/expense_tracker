import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService{

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }


  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Shows popup
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      // User cancelled
      if (googleUser == null) return null;

      // Get tokens
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication; //

      // Package for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      return await _auth.signInWithCredential(credential);

    } catch (e) {   //
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }


  Future<void> logout() async{
    await _auth.signOut();
    await _googleSignIn.signOut();

  }

  Future<void> resetPassword(String email) async{
    return await _auth.sendPasswordResetEmail(email: email);
  }
}