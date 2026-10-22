import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../providers.dart';

enum AutorMensaje { usuario, asistente }

/// Un mensaje de la conversación con el asistente (solo en memoria).
class MensajeAsistente {
  const MensajeAsistente({
    required this.texto,
    required this.autor,
    this.error = false,
    this.reintentarCon,
  });

  final String texto;
  final AutorMensaje autor;

  /// `true` si es un aviso de error (muestra "Reintentar").
  final bool error;

  /// Pregunta a reenviar al tocar "Reintentar".
  final String? reintentarCon;
}

class AsistenteState {
  const AsistenteState({required this.mensajes, this.escribiendo = false});

  final List<MensajeAsistente> mensajes;

  /// `true` mientras se espera la respuesta ("Escribiendo…").
  final bool escribiendo;

  /// Solo está el saludo inicial: se muestran las sugerencias.
  bool get esNueva => mensajes.length <= 1;

  AsistenteState copyWith({
    List<MensajeAsistente>? mensajes,
    bool? escribiendo,
  }) => AsistenteState(
    mensajes: mensajes ?? this.mensajes,
    escribiendo: escribiendo ?? this.escribiendo,
  );
}

const bienvenidaAsistente = MensajeAsistente(
  texto:
      '¡Hola! Soy el asistente de Lapticon. Puedo ayudarte a publicar una '
      'encomienda, registrar tu viaje o resolver dudas sobre cómo funciona '
      'la app. ¿En qué te ayudo?',
  autor: AutorMensaje.asistente,
);

/// Conversación con `POST /api/chatbot` (Notifier de Riverpod 3).
class AsistenteNotifier extends Notifier<AsistenteState> {
  @override
  AsistenteState build() =>
      const AsistenteState(mensajes: [bienvenidaAsistente]);

  /// Envía un mensaje del usuario y espera la respuesta.
  Future<void> enviar(String texto) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || state.escribiendo) return;
    state = state.copyWith(
      mensajes: [
        ...state.mensajes,
        MensajeAsistente(texto: pregunta, autor: AutorMensaje.usuario),
      ],
    );
    await _pedir(pregunta);
  }

  /// Quita el aviso de error y vuelve a pedir la misma respuesta.
  Future<void> reintentar(MensajeAsistente error) async {
    final pregunta = error.reintentarCon;
    if (pregunta == null || state.escribiendo) return;
    state = state.copyWith(
      mensajes: state.mensajes.where((m) => !identical(m, error)).toList(),
    );
    await _pedir(pregunta);
  }

  /// Empieza una conversación nueva.
  void reiniciar() => state = build();

  Future<void> _pedir(String pregunta) async {
    state = state.copyWith(escribiendo: true);
    MensajeAsistente respuesta;
    try {
      final texto = await ref.read(chatbotRepositoryProvider).enviar(pregunta);
      respuesta = MensajeAsistente(texto: texto, autor: AutorMensaje.asistente);
    } on AppException catch (e) {
      respuesta = MensajeAsistente(
        texto: mensajeErrorAsistente(e),
        autor: AutorMensaje.asistente,
        error: true,
        reintentarCon: pregunta,
      );
    }
    if (!ref.mounted) return;
    state = AsistenteState(
      mensajes: [...state.mensajes, respuesta],
      escribiendo: false,
    );
  }
}

/// Mensaje amable según el error (el backend puede no tener la clave de IA).
String mensajeErrorAsistente(AppException e) {
  if (e is NetworkException) return e.message;
  if (e is ApiException) {
    final m = e.message.toLowerCase();
    if (e.statusCode >= 500 ||
        m.contains('openrouter') ||
        m.contains('api key') ||
        m.contains('apikey')) {
      return 'El asistente no está disponible ahora. Intenta más tarde.';
    }
  }
  return e.message;
}

final asistenteProvider =
    NotifierProvider.autoDispose<AsistenteNotifier, AsistenteState>(
      AsistenteNotifier.new,
    );
