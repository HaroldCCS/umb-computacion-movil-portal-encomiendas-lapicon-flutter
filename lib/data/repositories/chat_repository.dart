import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/estado.dart';

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

  Future<EstadoChat> estado(String chatId) async {
    try {
      final json = await _api.get('/api/chats/estado/$chatId');
      return parseEstado(json);
    } on ApiException catch (e) {
      // Si el chat aún no existe se considera abierto. El endpoint responde
      // 500 incluso para chats reales (22-oct-2026): no debe bloquear el chat.
      if (e.isNotFound || e.statusCode >= 500) return EstadoChat.abierto;
      rethrow;
    }
  }

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
