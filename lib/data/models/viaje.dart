import 'estado.dart';
import 'json_utils.dart';

/// Viaje de un viajero (`/api/viajes`).
class Viaje {
  const Viaje({
    required this.id,
    required this.numeroVuelo,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.fechaViaje,
    required this.estado,
    this.viajeroUid,
    this.viajeroNombre,
  });

  final String id;
  final String numeroVuelo;
  final String ciudadOrigen;
  final String ciudadDestino;

  /// Fecha del vuelo (sin hora). Puede ser null si el backend no la envía.
  final DateTime? fechaViaje;
  final EstadoViaje estado;
  final String? viajeroUid;
  final String? viajeroNombre;

  factory Viaje.fromJson(dynamic json) {
    final map =
        unwrapObject(json, const ['viaje', 'data']) ??
        const <String, dynamic>{};
    String? uid;
    String? nombre;
    for (final key in const [
      'viajero',
      'viajeroUid',
      'usuario',
      'uid',
      'userId',
    ]) {
      final v = map[key];
      if (v is String && v.isNotEmpty) {
        uid = v;
        break;
      }
      if (v is Map) {
        final p = Map<String, dynamic>.from(v);
        final id = readString(p, const ['uid', '_id', 'id']);
        uid = id.isEmpty ? null : id;
        final n =
            '${readString(p, const ['nombre'])} '
                    '${readString(p, const ['apellido'])}'
                .trim();
        nombre = n.isEmpty ? null : n;
        break;
      }
    }
    return Viaje(
      id: readString(map, const ['_id', 'id']),
      numeroVuelo: readString(map, const ['numeroVuelo', 'vuelo']),
      ciudadOrigen: readString(map, const ['ciudadOrigen', 'origen']),
      ciudadDestino: readString(map, const ['ciudadDestino', 'destino']),
      fechaViaje: readDate(map, const ['fechaViaje', 'fecha']),
      estado: EstadoViaje.parse(map['estado']),
      viajeroUid: uid,
      viajeroNombre: nombre,
    );
  }

  /// Cuerpo de `POST /api/viajes` (igual al de Postman: fecha `YYYY-MM-DD`).
  static Map<String, dynamic> crearBody({
    required String numeroVuelo,
    required String ciudadOrigen,
    required String ciudadDestino,
    required DateTime fechaViaje,
  }) => {
    'numeroVuelo': numeroVuelo.replaceAll(' ', '').toUpperCase(),
    'ciudadOrigen': ciudadOrigen,
    'ciudadDestino': ciudadDestino,
    'fechaViaje': fechaIso(fechaViaje),
  };

  static String fechaIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
