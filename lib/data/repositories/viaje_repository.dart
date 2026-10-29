import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/json_utils.dart';
import '../models/viaje.dart';

/// Acceso a `/api/viajes` y `/api/vuelos` (docs/03 §3.2).
class ViajeRepository {
  ViajeRepository(this._api);

  final ApiClient _api;

  /// Historial de mis viajes (`GET /api/viajes`).
  Future<List<Viaje>> mios() async => _lista(await _api.get('/api/viajes'));

  /// Mi viaje activo (`GET /api/viajes/disponible`) o `null` si no hay.
  Future<Viaje?> disponible() async {
    try {
      final json = await _api.get('/api/viajes/disponible');
      if (json == null) return null;
      if (json is List) {
        final lista = _lista(json);
        return lista.isEmpty ? null : lista.first;
      }
      final viaje = Viaje.fromJson(json);
      return viaje.id.isEmpty ? null : viaje;
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// Viajeros que salen de [ciudad] (`GET /api/viajes/buscar?ciudad=`).
  Future<List<Viaje>> buscarPorOrigen(String ciudad) async =>
      _lista(await _api.get('/api/viajes/buscar', query: {'ciudad': ciudad}));

  /// `POST /api/viajes`. Responde 400 si ya hay un viaje activo.
  Future<Viaje> crear({
    required String numeroVuelo,
    required String ciudadOrigen,
    required String ciudadDestino,
    required DateTime fechaViaje,
  }) async {
    final json = await _api.post(
      '/api/viajes',
      body: Viaje.crearBody(
        numeroVuelo: numeroVuelo,
        ciudadOrigen: ciudadOrigen,
        ciudadDestino: ciudadDestino,
        fechaViaje: fechaViaje,
      ),
    );
    return Viaje.fromJson(json);
  }

  /// Valida el vuelo con AeroDataBox (`GET /api/vuelos/:numero/:fecha`).
  /// Devuelve la respuesta cruda (forma aún no confirmada) o lanza
  /// [ApiException] (404 = vuelo no encontrado). No se usa en la interfaz
  /// mientras el servidor responda 500 (`RAPIDAPI_KEY`); ver docs/11 §2H.
  Future<Map<String, dynamic>> validarVuelo(
    String numero,
    DateTime fecha,
  ) async {
    final json = await _api.get(
      '/api/vuelos/${numero.replaceAll(' ', '').toUpperCase()}/'
      '${Viaje.fechaIso(fecha)}',
    );
    if (json is Map) return Map<String, dynamic>.from(json);
    if (json is List && json.isNotEmpty && json.first is Map) {
      return Map<String, dynamic>.from(json.first as Map);
    }
    return const {};
  }

  List<Viaje> _lista(dynamic json) => unwrapList(json, const [
    'viajes',
    'data',
    'items',
    'viajeros',
  ]).whereType<Map>().map(Viaje.fromJson).toList();
}
