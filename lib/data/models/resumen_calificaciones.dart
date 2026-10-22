import 'json_utils.dart';

/// Respuesta de `GET /api/ratings/:uid`
/// (verificada: `{ "total": 0, "promedio": null, "calificaciones": [] }`).
class ResumenCalificaciones {
  const ResumenCalificaciones({
    required this.total,
    required this.promedio,
    required this.calificaciones,
  });

  final int total;
  final double? promedio;
  final List<Calificacion> calificaciones;

  factory ResumenCalificaciones.fromJson(dynamic json) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    final lista = unwrapList(map, const ['calificaciones', 'ratings'])
        .whereType<Map>()
        .map((m) => Calificacion.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return ResumenCalificaciones(
      total: readNum(map, const ['total'])?.toInt() ?? lista.length,
      promedio: readNum(map, const ['promedio', 'average'])?.toDouble(),
      calificaciones: lista,
    );
  }

  bool get vacio => total == 0;
}

class Calificacion {
  const Calificacion({
    required this.calificacion,
    required this.comentario,
    this.rolDestino,
    this.fecha,
  });

  final int calificacion;
  final String comentario;
  final String? rolDestino;
  final DateTime? fecha;

  factory Calificacion.fromJson(Map<String, dynamic> json) {
    final rol = readString(json, const ['rolDestino']);
    return Calificacion(
      calificacion:
          (readNum(json, const ['calificacion', 'rating'])?.round() ?? 0).clamp(
            0,
            5,
          ),
      comentario: readString(json, const ['comentario', 'comment']),
      rolDestino: rol.isEmpty ? null : rol,
      fecha: readDate(json, const ['timestamp', 'createdAt', 'fecha']),
    );
  }
}
