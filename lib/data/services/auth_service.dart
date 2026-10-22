import 'package:firebase_auth/firebase_auth.dart';

import '../../core/network/app_exception.dart';

/// Envoltura de Firebase Auth. Firebase es el único proveedor de identidad:
/// el backend solo verifica el idToken que obtenemos aquí.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// idToken para el header `Authorization: Bearer`. Firebase lo cachea y lo
  /// renueva solo; con [forceRefresh] se pide uno nuevo (p. ej. tras un 401).
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  Future<void> iniciarSesion(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> crearCuenta(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> recuperarPassword(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> cerrarSesion() => _auth.signOut();

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(mensajeAuth(e.code), code: e.code);
    }
  }

  /// Traduce los códigos de Firebase Auth a mensajes claros.
  static String mensajeAuth(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'No hay conexión. Revisa tu internet.';
      case 'operation-not-allowed':
        return 'Este método de inicio de sesión no está habilitado.';
      default:
        return 'No pudimos completar la operación ($code).';
    }
  }
}

class AuthException extends AppException {
  const AuthException(super.message, {required this.code});

  /// Código original de Firebase (p. ej. `user-not-found`).
  final String code;
}
