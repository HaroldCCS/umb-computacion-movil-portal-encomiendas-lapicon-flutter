import '../../core/network/api_client.dart';
import '../local/prefs.dart';
import '../models/json_utils.dart';

/// Países y ciudades (`/api/ciudades/*`, públicas). Se cachean 7 días porque
/// la lista de ciudades es grande (~2.000) y casi no cambia.
class CatalogoRepository {
  CatalogoRepository(this._api, this._prefs);

  final ApiClient _api;
  final Prefs _prefs;

  Future<List<String>> paises() => _lista('paises', '/api/ciudades/paises');

  Future<List<String>> ciudades() =>
      _lista('ciudades', '/api/ciudades/ciudades');

  Future<List<String>> _lista(String key, String path) async {
    final cached = _prefs.listaCacheada(key);
    if (cached != null && cached.isNotEmpty) return cached;

    final json = await _api.get(path, auth: false);
    final limpia = limpiarLista(
      unwrapList(json, const ['data', 'paises', 'ciudades']),
    );
    if (limpia.isNotEmpty) await _prefs.guardarLista(key, limpia);
    return limpia;
  }

  /// Quita nombres con caracteres corruptos y duplicados que difieren solo en
  /// mayúsculas, y ordena alfabéticamente.
  static List<String> limpiarLista(List<dynamic> raw) {
    final vistos = <String>{};
    final resultado = <String>[];
    for (final item in raw) {
      if (item is! String) continue;
      final nombre = item.trim();
      if (nombre.isEmpty) continue;
      if (nombre.contains('�') || nombre.contains('ï¿½')) continue;
      if (vistos.add(nombre.toLowerCase())) resultado.add(nombre);
    }
    resultado.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return resultado;
  }
}
