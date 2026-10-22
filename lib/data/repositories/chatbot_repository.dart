import '../../core/network/api_client.dart';
import '../models/json_utils.dart';

/// Asistente con IA (`POST /api/chatbot`, requiere token; depende de que el
/// backend tenga OPENROUTER_API_KEY).
class ChatbotRepository {
  ChatbotRepository(this._api);

  final ApiClient _api;

  /// Devuelve el texto de respuesta del asistente.
  Future<String> enviar(String mensajeUsuario) async {
    final json = await _api.post(
      '/api/chatbot',
      body: {'mensajeUsuario': mensajeUsuario},
    );
    if (json is String) return json;
    if (json is Map) {
      final texto = readString(Map<String, dynamic>.from(json), const [
        'respuesta',
        'mensaje',
        'reply',
        'message',
        'content',
        'text',
      ]);
      if (texto.isNotEmpty) return texto;
    }
    return 'No recibí una respuesta del asistente.';
  }
}
