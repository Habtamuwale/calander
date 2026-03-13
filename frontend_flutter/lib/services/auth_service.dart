import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (e) {
      print("Signup Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (e) {
      print("Signin Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
