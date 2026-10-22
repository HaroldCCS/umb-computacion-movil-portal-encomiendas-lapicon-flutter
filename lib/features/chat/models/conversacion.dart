import 'mensaje_chat.dart';

/// Documento `chats/{chatId}` en Firestore (estructura propuesta, docs/03):
/// `{ participantes, nombres: {uid: nombre}, encomiendaId?, ruta?,
///    ultimoMensaje, ultimoEmisorUid, actualizadoEn }`.
class Conversacion {
  const Conversacion({
    required this.id,
    required this.participantes,
    required this.nombres,
    this.encomiendaId,
    this.ruta,
    this.ultimoMensaje,
    this.ultimoEmisorUid,
    this.actualizadoEn,
  });

  final String id;
  final List<String> participantes;
  final Map<String, String> nombres;
  final String? encomiendaId;
  final String? ruta;
  final String? ultimoMensaje;
  final String? ultimoEmisorUid;
  final DateTime? actualizadoEn;

  factory Conversacion.fromMap(String id, Map<String, dynamic> data) {
    final participantes = data['participantes'] is List
        ? (data['participantes'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : id.split('_').where((e) => e.isNotEmpty).toList();
    final nombres = <String, String>{};
    final rawNombres = data['nombres'];
    if (rawNombres is Map) {
      rawNombres.forEach((k, v) {
        final nombre = v?.toString().trim() ?? '';
        if (nombre.isNotEmpty) nombres[k.toString()] = nombre;
      });
    }
    return Conversacion(
      id: id,
      participantes: participantes,
      nombres: nombres,
      encomiendaId: _texto(data['encomiendaId']),
      ruta: _texto(data['ruta']),
      ultimoMensaje: _texto(data['ultimoMensaje']),
      ultimoEmisorUid: _texto(data['ultimoEmisorUid']),
      actualizadoEn: leerFecha(data['actualizadoEn']),
    );
  }

  /// uid de la otra persona (el chat es siempre entre dos).
  String? otroUid(String miUid) {
    for (final p in participantes) {
      if (p != miUid) return p;
    }
    return null;
  }

  String nombreDe(String? uid) {
    if (uid == null) return 'Usuario';
    return nombres[uid] ?? 'Usuario';
  }

  /// Más recientes primero; las que tienen la hora pendiente van arriba.
  static List<Conversacion> ordenar(List<Conversacion> lista) {
    final copia = [...lista];
    copia.sort((a, b) {
      final fa = a.actualizadoEn;
      final fb = b.actualizadoEn;
      if (fa == null && fb == null) return 0;
      if (fa == null) return -1;
      if (fb == null) return 1;
      return fb.compareTo(fa);
    });
    return copia;
  }

  static String? _texto(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }
}

/// Iniciales para el avatar ("Laura Gómez" → "LG").
String inicialesDe(String nombre) {
  final partes = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .toList();
  if (partes.isEmpty) return '?';
  return partes
      .map((p) => String.fromCharCode(p.runes.first).toUpperCase())
      .join();
}
