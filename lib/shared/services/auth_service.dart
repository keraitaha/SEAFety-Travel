import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    String? country,
    String? gender,
    String? dob,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      await _userService.createUserDoc(
        userid: uid,
        firstname: firstname.trim(),
        lastname: lastname.trim(),
        email: email.trim(),
        country: country,
        gender: gender,
        dob: dob,
        role: 0,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
