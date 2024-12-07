import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tablets/src/common/functions/debug_print.dart' as debug;

class AuthRepository {
  AuthRepository(this._authRepository);
  final FirebaseAuth _authRepository;

  /// to login user using his email and password
  /// return true if login was successful, otherwise return false
  Future<bool> signUserIn(String email, String password) async {
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (error) {
      debug.errorPrint(error, stackTrace: StackTrace.current);
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authRepository = FirebaseAuth.instance;
  return AuthRepository(authRepository);
});
