import '../../core/network/api_client.dart';
import '../models/encomienda.dart';
import '../models/estado.dart';
import '../models/json_utils.dart';

/// Acceso a `/api/encomiendas` (docs/03 §3.2). Contrato compartido por las
/// funcionalidades de remitente y viajero: no cambiar firmas sin avisar.
class EncomiendaRepository {
  EncomiendaRepository(this._api);

  final ApiClient _api;

  /// Mis encomiendas como remitente (`GET /api/encomiendas`).
  Future<List<Encomienda>> mias() async =>
      _lista(await _api.get('/api/encomiendas'));

  /// Encomiendas que un viajero puede tomar en su ruta
  /// (`GET /api/encomiendas/disponibles?origen=&destino=`).
  Future<List<Encomienda>> disponibles({
    required String origen,
    required String destino,
  }) async => _lista(
    await _api.get(
      '/api/encomiendas/disponibles',
      query: {'origen': origen, 'destino': destino},
    ),
  );

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
