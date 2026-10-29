import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../models/estado.dart';
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

  /// Viajeros con viaje disponible en una ruta, con su nombre
  /// (`GET /api/viajes/disponibles`, pública). Solo trae ruta, fecha, `uid` y
  /// `nombreUsuario`: ni vuelo ni estado.
  Future<List<Viaje>> disponiblesEnRuta(String origen, String destino) async =>
      _lista(
        await _api.get(
          '/api/viajes/disponibles',
          query: {'ciudadOrigen': origen, 'ciudadDestino': destino},
          auth: false,
        ),
      );

  /// Cancela o cierra mi viaje (`PATCH /api/viajes/{id}/estado`). Después se
  /// puede registrar otro. 404 si no es mío. El servidor no revisa si lleva
  /// encomiendas: eso lo hace la pantalla.
  Future<Viaje?> cambiarEstado(String id, EstadoViaje estado) async {
    assert(estado == EstadoViaje.cancelado || estado == EstadoViaje.completado);
    final json = await _api.patch(
      '/api/viajes/$id/estado',
      body: {'estado': estado.name},
    );
    final viaje = Viaje.fromJson(json);
    return viaje.id.isEmpty ? null : viaje;
  }

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

  /// Valida el vuelo con AeroDataBox (`GET /api/vuelos/:numero/:fecha`,
  /// pública: sin token).
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
      auth: false,
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
