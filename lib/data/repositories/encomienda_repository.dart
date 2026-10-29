import '../../core/network/api_client.dart';
import '../models/encomienda.dart';
import '../models/estado.dart';
import '../models/json_utils.dart';
import '../models/viaje.dart';

/// Un viaje sugerido por `POST /api/encomiendas/emparejar-viajes` (sin
/// nombre del viajero).
class ViajeSugerido {
  const ViajeSugerido({
    required this.viajeId,
    required this.viajeroUid,
    required this.afinidad,
    this.fechaViaje,
  });

  final String viajeId;
  final String viajeroUid;

  /// 0 a 1.
  final double afinidad;
  final DateTime? fechaViaje;
}

/// Respuesta de `GET /api/encomiendas/buscar`.
class BusquedaEncomiendas {
  const BusquedaEncomiendas({
    this.disponibles = const [],
    this.tomadas = const [],
  });

  final List<Encomienda> disponibles;
  final List<Encomienda> tomadas;
}

/// Acceso a `/api/encomiendas` (docs/03 §3.2). Contrato compartido por las
/// funcionalidades de remitente y viajero: no cambiar firmas sin avisar.
class EncomiendaRepository {
  EncomiendaRepository(this._api);

  final ApiClient _api;

  /// Mis encomiendas como remitente (`GET /api/encomiendas`).
  Future<List<Encomienda>> mias() async =>
      _lista(await _api.get('/api/encomiendas'));

  /// Viajero, en una ruta (`GET /api/encomiendas/buscar?origen=&destino=`):
  /// las disponibles (incluye las mías como remitente) y las que tomé, solo
  /// mientras siguen `tomada`. Todas con `uid` y `remitenteNombre`.
  Future<BusquedaEncomiendas> buscar({
    required String origen,
    required String destino,
  }) async {
    final json = await _api.get(
      '/api/encomiendas/buscar',
      query: {'origen': origen, 'destino': destino},
    );
    final m = json is Map ? json : const {};
    return BusquedaEncomiendas(
      disponibles: _lista(m['disponibles'] ?? const []),
      tomadas: _lista(m['tomadas'] ?? const []),
    );
  }

  /// Viajes sugeridos por IA para una encomienda
  /// (`POST /api/encomiendas/emparejar-viajes`, docs/11 §2F). Una vez tardó más
  /// de 120 s: quien la use le pone su propio tiempo de espera.
  Future<List<ViajeSugerido>> emparejar({
    required String ciudadOrigen,
    required String ciudadDestino,
    required DateTime fecha,
    required num valor,
  }) async {
    final json = await _api.post(
      '/api/encomiendas/emparejar-viajes',
      body: {
        'ciudadOrigen': ciudadOrigen,
        'ciudadDestino': ciudadDestino,
        'fechaEncomienda': Viaje.fechaIso(fecha),
        'valorEncomienda': valor,
      },
    );
    return [
      for (final m in unwrapList(json, const [
        'viajes',
        'sugerencias',
        'data',
      ]).whereType<Map>())
        if (readString(Map<String, dynamic>.from(m), const [
          'uid',
          'viajeroUid',
        ]).isNotEmpty)
          ViajeSugerido(
            viajeId: readString(Map<String, dynamic>.from(m), const [
              'viajeId',
              '_id',
              'id',
            ]),
            viajeroUid: readString(Map<String, dynamic>.from(m), const [
              'uid',
              'viajeroUid',
            ]),
            afinidad:
                (readNum(Map<String, dynamic>.from(m), const ['afinidad']) ?? 0)
                    .clamp(0, 1)
                    .toDouble(),
            fechaViaje: readDate(Map<String, dynamic>.from(m), const [
              'fechaViaje',
            ]),
          ),
    ];
  }

  /// `POST /api/encomiendas`. Devuelve la encomienda creada (con `_id`).
  Future<Encomienda> crear({
    required String ciudadOrigen,
    required String ciudadDestino,
    required String observaciones,
    required String moneda,
    required num valor,
  }) async {
    final json = await _api.post(
      '/api/encomiendas',
      body: Encomienda.crearBody(
        ciudadOrigen: ciudadOrigen,
        ciudadDestino: ciudadDestino,
        observaciones: observaciones,
        moneda: moneda,
        valor: valor,
      ),
    );
    return Encomienda.fromJson(json);
  }

  /// El viajero toma la encomienda (`PUT /api/encomiendas/tomar/:id`).
  /// Responde solo `{ mensaje }` (sin la encomienda), así que suele devolver
  /// `null` y la vista actualiza el estado localmente.
  Future<Encomienda?> tomar(String id) async {
    final json = await _api.put('/api/encomiendas/tomar/$id');
    final e = json is Map ? Encomienda.fromJson(json) : null;
    return (e != null && e.id.isNotEmpty) ? e : null;
  }

  /// Cambia el estado (`PUT /api/encomiendas/:id/estado`), p. ej. `vencida`
  /// (el remitente la retira) o `entregada` (viajero asignado). Responde
  /// `{ mensaje, encomienda }`.
  Future<Encomienda?> cambiarEstado(String id, EstadoEncomienda estado) async {
    final json = await _api.put(
      '/api/encomiendas/$id/estado',
      body: {'estado': estado.apiValue},
    );
    return json is Map ? Encomienda.fromJson(json) : null;
  }

  List<Encomienda> _lista(dynamic json) =>
      unwrapList(json, const ['encomiendas', 'data', 'items'])
          .whereType<Map>()
          .map(Encomienda.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList();
}
