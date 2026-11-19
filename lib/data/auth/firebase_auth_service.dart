import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// [AuthService] sobre o Firebase Authentication (email e senha).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signUp({required String email, required String password}) =>
      _guard(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _auth.signOut();

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.uid, email: user.email);

  static Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e.code));
    }
  }
}
