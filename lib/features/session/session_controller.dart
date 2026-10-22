import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../../core/network/app_exception.dart';
import '../../data/local/prefs.dart';
import '../../data/models/rol.dart';
import '../../data/models/usuario.dart';
import '../../data/repositories/usuario_repository.dart';
import '../../data/services/auth_service.dart';

/// En qué punto del recorrido está el usuario. El router redirige según esto.
enum SessionStatus {
  /// Revisando la sesión o cargando el perfil.
  cargando,

  /// Sin sesión de Firebase → login.
  sinSesion,

  /// Con sesión pero sin perfil en el backend → completar perfil.
  sinPerfil,

  /// Con perfil pero sin rol elegido → elegir rol.
  sinRol,

  /// Todo listo → inicio del rol.
  listo,

  /// No se pudo cargar el perfil (red, servidor) → pantalla de reintento.
  error,
}

/// Estado global de la sesión: usuario de Firebase + perfil + rol.
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthService auth,
    required UsuarioRepository usuarios,
    required Prefs prefs,
  }) : _auth = auth,
       _usuarios = usuarios,
       _prefs = prefs {
    _sub = _auth.authStateChanges().listen(_onUserChanged);
  }

  final AuthService _auth;
  final UsuarioRepository _usuarios;
  final Prefs _prefs;
  late final StreamSubscription<User?> _sub;

  SessionStatus _status = SessionStatus.cargando;
  User? _user;
  Usuario? _perfil;
  Rol? _rol;
  String? _error;
  bool _rolEnServidor = false;
  int _generation = 0;

  SessionStatus get status => _status;
  User? get user => _user;
  Usuario? get perfil => _perfil;
  Rol? get rol => _rol;
  String? get error => _error;

  /// `true` si el backend confirmó que guardó el rol (reto 1).
  bool get rolEnServidor => _rolEnServidor;

  String? get email => _user?.email;

  Future<void> _onUserChanged(User? user) async {
    _user = user;
    if (user == null) {
      _generation++;
      _perfil = null;
      _rol = null;
      _error = null;
      _setStatus(SessionStatus.sinSesion);
      return;
    }
    await recargar();
  }

  /// Carga el perfil del backend y decide el siguiente paso.
  ///
  /// Con [silencioso] (p. ej. "deslizar para actualizar") no pasa por la
  /// pantalla de carga y, si falla, lanza el error para que la vista lo muestre.
  Future<void> recargar({bool silencioso = false}) async {
    final user = _user;
    if (user == null) return;
    final generation = ++_generation;
    if (!silencioso) {
      _error = null;
      _setStatus(SessionStatus.cargando);
    }

    try {
      final perfil = await _usuarios.obtener(user.uid);
      if (generation != _generation) return; // llegó otra sesión mientras tanto

      if (perfil == null || !perfil.completo) {
        _perfil = perfil;
        _setStatus(SessionStatus.sinPerfil);
        return;
      }

      _perfil = perfil.copyWith(email: user.email);
      _rolEnServidor = perfil.rol != null;
      _rol = perfil.rol ?? _prefs.rol(user.uid);
      if (_rol != null) await _prefs.guardarRol(user.uid, _rol!);
      _setStatus(_rol == null ? SessionStatus.sinRol : SessionStatus.listo);
    } on AppException catch (e) {
      if (generation != _generation) return;
      if (silencioso) rethrow;
      _error = e.message;
      _setStatus(SessionStatus.error);
    }
  }

  /// Primer registro del perfil (Completar perfil).
  Future<void> registrarPerfil(Usuario datos) async {
    final user = _user;
    if (user == null) throw const NotAuthenticatedException();
    final guardado = await _usuarios.registrar(datos);
    _perfil = guardado.copyWith(email: user.email);
    _rol = _perfil!.rol ?? _prefs.rol(user.uid);
    _setStatus(_rol == null ? SessionStatus.sinRol : SessionStatus.listo);
  }

  /// Edición del perfil desde la pantalla de perfil.
  Future<void> actualizarPerfil(Usuario datos) async {
    final user = _user;
    if (user == null) throw const NotAuthenticatedException();
    final guardado = await _usuarios.actualizar(datos);
    _perfil = guardado.copyWith(email: user.email, rol: _rol);
    notifyListeners();
  }

  /// Guarda el rol en el backend (si lo acepta) y siempre en caché local.
  Future<void> elegirRol(Rol rol) async {
    final user = _user;
    if (user == null) throw const NotAuthenticatedException();
    await _prefs.guardarRol(user.uid, rol);
    try {
      _rolEnServidor = await _usuarios.guardarRol(user.uid, rol);
    } on AppException {
      // Si el backend no lo soporta o falla, el rol queda en caché local.
      _rolEnServidor = false;
    }
    _rol = rol;
    _perfil = _perfil?.copyWith(rol: rol);
    _setStatus(SessionStatus.listo);
  }

  Future<void> cerrarSesion() => _auth.cerrarSesion();

  void _setStatus(SessionStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
