import '../../core/network/api_client.dart';
import '../models/resumen_calificaciones.dart';
import '../models/rol.dart';

/// Calificaciones (`/api/ratings`). Consultar es público; calificar
/// (Práctica 6) requiere token.
class CalificacionesRepository {
  CalificacionesRepository(this._api);

  final ApiClient _api;

  Future<ResumenCalificaciones> resumen(String uid) async {
    final json = await _api.get('/api/ratings/$uid', auth: false);
    return ResumenCalificaciones.fromJson(json);
  }

  /// `POST /api/ratings` (body de Postman). El backend ignora `encomiendaId`
  /// (22-oct-2026); se envía igual por si lo empieza a usar.
  Future<void> calificar({
    required String usuarioDestino,
    required Rol rolDestino,
    required int calificacion,
    String comentario = '',
    String? encomiendaId,
  }) async {
    await _api.post(
      '/api/ratings',
      body: {
        'usuarioDestino': usuarioDestino,
        'rolDestino': rolDestino.name,
        'calificacion': calificacion.clamp(1, 5),
        'comentario': comentario.trim(),
        'encomiendaId': ?encomiendaId,
      },
    );
  }
}
