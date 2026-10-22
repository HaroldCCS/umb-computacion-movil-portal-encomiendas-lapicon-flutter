import 'estado.dart';
import 'json_utils.dart';

/// Encomienda (`/api/encomiendas`). Forma confirmada (22-oct-2026): el
/// remitente viene en `uid`, el viajero en `viajeroId`, y en
/// `/disponibles` llega `remitenteNombre` pero no el `uid` (docs/03 §3.3).
class Encomienda {
  const Encomienda({
    required this.id,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.observaciones,
    required this.moneda,
    required this.valor,
    required this.estado,
    this.remitenteUid,
    this.viajeroUid,
    this.remitenteNombre,
    this.viajeroNombre,
    this.fechaVencimiento,
    this.creadaEn,
  });

  final String id;
  final String ciudadOrigen;
  final String ciudadDestino;
  final String observaciones;
  final String moneda;
  final num valor;
  final EstadoEncomienda estado;
  final String? remitenteUid;
  final String? viajeroUid;
  final String? remitenteNombre;
  final String? viajeroNombre;
  final DateTime? fechaVencimiento;
  final DateTime? creadaEn;

  factory Encomienda.fromJson(dynamic json) {
    final map =
        unwrapObject(json, const ['encomienda', 'data']) ??
        const <String, dynamic>{};
    final remitente = _persona(map, const [
      'remitente',
      'remitenteUid',
      'remitenteId',
      'usuario',
      'userId',
      'uid',
    ]);
    final viajero = _persona(map, const [
      'viajero',
      'viajeroUid',
      'viajeroId',
      'tomadaPor',
    ]);
    return Encomienda(
      id: readString(map, const ['_id', 'id']),
      ciudadOrigen: readString(map, const ['ciudadOrigen', 'origen']),
      ciudadDestino: readString(map, const ['ciudadDestino', 'destino']),
      observaciones: readString(map, const ['observaciones', 'descripcion']),
      moneda: readString(map, const ['moneda']).isEmpty
          ? 'USD'
          : readString(map, const ['moneda']),
      valor: readNum(map, const ['valor', 'precio']) ?? 0,
      estado: EstadoEncomienda.parse(map['estado']),
      remitenteUid: remitente.$1,
      remitenteNombre: remitente.$2 ?? _texto(map, 'remitenteNombre'),
      viajeroUid: viajero.$1,
      viajeroNombre: viajero.$2 ?? _texto(map, 'viajeroNombre'),
      fechaVencimiento: readDate(map, const [
        'fechaVencimiento',
        'fechaLimite',
      ]),
      creadaEn: readDate(map, const ['createdAt', 'fechaCreacion']),
    );
  }

  /// Cuerpo de `POST /api/encomiendas` (igual al de Postman). El backend
  /// ignora `fechaVencimiento`: siempre vence un mes después de creada.
  static Map<String, dynamic> crearBody({
    required String ciudadOrigen,
    required String ciudadDestino,
    required String observaciones,
    required String moneda,
    required num valor,
  }) => {
    'ciudadOrigen': ciudadOrigen,
    'ciudadDestino': ciudadDestino,
    'observaciones': observaciones,
    'moneda': moneda,
    'valor': valor,
  };

  static String? _texto(Map<String, dynamic> map, String key) {
    final v = readString(map, [key]);
    return v.isEmpty ? null : v;
  }

  /// Lee un campo que puede ser el uid (String) o el usuario "populado"
  /// (`{ uid, nombre, apellido }`). Devuelve (uid, nombre).
  static (String?, String?) _persona(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return (value.trim(), null);
      }
      if (value is Map) {
        final p = Map<String, dynamic>.from(value);
        final uid = readString(p, const ['uid', 'firebaseUid', '_id', 'id']);
        final nombre =
            '${readString(p, const ['nombre'])} '
                    '${readString(p, const ['apellido'])}'
                .trim();
        return (uid.isEmpty ? null : uid, nombre.isEmpty ? null : nombre);
      }
    }
    return (null, null);
  }
}
