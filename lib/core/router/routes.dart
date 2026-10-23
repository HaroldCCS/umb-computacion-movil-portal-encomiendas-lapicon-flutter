import '../../data/models/encomienda.dart';
import '../../data/models/rol.dart';

/// Contrato de rutas. Cada funcionalidad registra sus propias rutas en su
/// archivo `*_routes.dart` usando SOLO su prefijo:
///   remitente → `/remitente/...`   viajero → `/viajero/...`
/// Las rutas compartidas entre funcionalidades están aquí con sus argumentos.
abstract final class Routes {
  // Sesión y onboarding (Práctica 1)
  static const splash = '/splash';
  static const login = '/login';
  static const registro = '/registro';
  static const recuperar = '/recuperar';
  static const completarPerfil = '/completar-perfil';
  static const elegirRol = '/elegir-rol';
  static const inicio = '/inicio';
  static const editarPerfil = '/perfil/editar';

  static const publicas = {login, registro, recuperar};

  /// Chat entre remitente y viajero. `extra`: [ChatArgs].
  /// Lo implementa features/chat.
  static const chat = '/chat';

  /// Formulario para calificar. `extra`: [CalificarArgs].
  /// Al cerrar devuelve `true` (con `context.pop(true)`) si se calificó.
  /// Lo implementa features/calificaciones.
  static const calificar = '/calificar';

  /// Asistente con IA (`POST /api/chatbot`). Lo implementa features/asistente.
  static const asistente = '/asistente';
}

/// Acción pendiente a la que lleva un aviso: el detalle abre con esa acción
/// visible y resaltada (docs/08 §8.4, "los enlaces llevan directo a donde
/// está la acción"). Va como `?accion=` en la ruta del detalle.
enum AccionPendiente {
  calificar,
  entregar;

  static AccionPendiente? deRuta(Map<String, String> query) {
    final valor = query['accion'];
    for (final a in values) {
      if (a.name == valor) return a;
    }
    return null;
  }

  /// `/remitente/encomienda` → `/remitente/encomienda?accion=calificar`.
  String en(String ruta) => '$ruta?accion=$name';
}

/// Argumentos de [Routes.chat].
class ChatArgs {
  const ChatArgs({required this.otroUid, this.otroNombre, this.encomienda});

  /// uid de Firebase de la otra persona.
  final String otroUid;
  final String? otroNombre;

  /// Encomienda sobre la que se conversa (para mostrar la ruta arriba).
  final Encomienda? encomienda;
}

/// Argumentos de [Routes.calificar].
class CalificarArgs {
  const CalificarArgs({
    required this.usuarioDestino,
    required this.rolDestino,
    this.nombreDestino,
    this.encomienda,
  });

  final String usuarioDestino;

  /// Rol de la persona calificada (el remitente califica al `viajero`).
  final Rol rolDestino;
  final String? nombreDestino;
  final Encomienda? encomienda;
}
