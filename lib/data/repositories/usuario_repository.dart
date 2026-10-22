import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/rol.dart';
import '../models/usuario.dart';

/// Acceso a `/api/users`. Todas las rutas son protegidas (Bearer idToken) y
/// el backend solo deja ver/editar el perfil propio (otro uid → 403).
class UsuarioRepository {
  UsuarioRepository(this._api);

  final ApiClient _api;

  /// Devuelve el perfil o `null` si el usuario aún no se ha registrado.
  Future<Usuario?> obtener(String uid) async {
    try {
      final json = await _api.get('/api/users/$uid');
      if (json == null) return null;
      return Usuario.fromJson(json, uidFallback: uid);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Crea o actualiza el perfil propio (`POST /api/users/register`).
  Future<Usuario> registrar(Usuario datos) async {
    final json = await _api.post(
      '/api/users/register',
      body: datos.toRegisterJson(),
    );
    return _merge(json, datos);
  }

  /// Actualiza campos del perfil propio (`PUT /api/users/:uid`).
  Future<Usuario> actualizar(Usuario datos) async {
    final json = await _api.put(
      '/api/users/${datos.uid}',
      body: datos.toRegisterJson(),
    );
    return _merge(json, datos);
  }

  /// Intenta guardar el rol en el backend (reto 1). Devuelve `false` si el
  /// backend no lo acepta; en ese caso el rol queda solo en caché local.
  Future<bool> guardarRol(String uid, Rol rol) async {
    try {
      final json = await _api.put('/api/users/$uid', body: {'rol': rol.name});
      // Solo se considera guardado si el backend devuelve el campo `rol`.
      return Usuario.fromJson(json, uidFallback: uid).rol == rol;
    } on ApiException catch (e) {
      if (e.isBusinessRule) return false;
      rethrow;
    }
  }

  /// Si el backend devuelve el perfil, se usa; si no, se conserva lo enviado.
  Usuario _merge(dynamic json, Usuario enviado) {
    if (json is! Map) return enviado;
    final recibido = Usuario.fromJson(json, uidFallback: enviado.uid);
    return recibido.completo
        ? recibido.copyWith(email: enviado.email, rol: enviado.rol)
        : enviado;
  }
}
