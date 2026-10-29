import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/estado.dart';
import '../models/json_utils.dart';

/// Parte REST del chat: solo consulta si sigue abierto
/// (`GET /api/chats/estado/:chatId`). Los mensajes van por Firestore
/// (ver features/chat).
class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  /// El id del chat es `uid1_uid2` con los uid ordenados: el mismo par de
  /// usuarios siempre abre el mismo documento.
  static String chatId(String uidA, String uidB) =>
      ([uidA, uidB]..sort()).join('_');

  /// `{ estado: activo | cerrado, fechaCierre }` (28-oct-2026). El backend
  /// abre el chat del par al tomar una encomienda y lo cierra al marcarla
  /// entregada.
  Future<({EstadoChat estado, DateTime? fechaCierre})> detalleEstado(
    String chatId,
  ) async {
    try {
      final json = await _api.get('/api/chats/estado/$chatId');
      final estado = parseEstado(json);
      return (
        estado: estado,
        fechaCierre: estado == EstadoChat.cerrado && json is Map
            ? readDate(Map<String, dynamic>.from(json), const ['fechaCierre'])
            : null,
      );
    } on ApiException catch (e) {
      // Si el chat no existe (404) o el servidor falla, se considera
      // abierto: no debe bloquear el chat.
      if (e.isNotFound || e.statusCode >= 500) {
        return (estado: EstadoChat.abierto, fechaCierre: null);
      }
      rethrow;
    }
  }

  /// Solo abierto/cerrado (para revisar antes de cada envío).
  Future<EstadoChat> estado(String chatId) async =>
      (await detalleEstado(chatId)).estado;

  static EstadoChat parseEstado(dynamic json) {
    if (json is Map) {
      final estado = json['estado']?.toString().toLowerCase();
      if (estado == 'cerrado' || estado == 'closed') return EstadoChat.cerrado;
      if (json['cerrado'] == true || json['abierto'] == false) {
        return EstadoChat.cerrado;
      }
    }
    if (json is String && json.toLowerCase().contains('cerrado')) {
      return EstadoChat.cerrado;
    }
    return EstadoChat.abierto;
  }
}
