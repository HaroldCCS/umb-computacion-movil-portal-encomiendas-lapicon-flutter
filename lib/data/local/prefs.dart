import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/rol.dart';

/// Persistencia local ligera. El rol vive en el backend (si lo acepta) y aquí
/// solo como caché, como propone el reto 1 del taller.
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static const _cacheTtl = Duration(days: 7);

  Rol? rol(String uid) => Rol.tryParse(_prefs.getString('rol_$uid'));

  Future<void> guardarRol(String uid, Rol rol) =>
      _prefs.setString('rol_$uid', rol.name);

  Future<void> borrarRol(String uid) => _prefs.remove('rol_$uid');

  /// Encomiendas que este usuario ya calificó desde este teléfono. El
  /// backend ignora `encomiendaId` al calificar (docs/03), así que es la
  /// única forma de saber qué entregas siguen "por calificar".
  Set<String> calificadas(String uid) => {
    ...?_prefs.getStringList('calificadas_$uid'),
  };

  Future<void> marcarCalificada(String uid, String encomiendaId) =>
      _prefs.setStringList('calificadas_$uid', [
        ...{...calificadas(uid), encomiendaId},
      ]);

  /// Último estado visto de cada encomienda del remitente (`id → estado`),
  /// para avisar cuando un viajero la toma (docs/11 §2G). `null` si nunca se
  /// guardó.
  Map<String, String>? estadosVistos(String uid) {
    final raw = _prefs.getString('remitente_estados_vistos_$uid');
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final par in m.entries)
          if (par.value is String) par.key: par.value as String,
      };
    } on Object {
      return null;
    }
  }

  Future<void> guardarEstadosVistos(String uid, Map<String, String> vistos) =>
      _prefs.setString('remitente_estados_vistos_$uid', jsonEncode(vistos));

  /// Lista de strings cacheada (países, ciudades) con fecha de vencimiento.
  List<String>? listaCacheada(String key) {
    final raw = _prefs.getString('cache_$key');
    final savedAt = _prefs.getInt('cache_${key}_at');
    if (raw == null || savedAt == null) return null;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
    if (age > _cacheTtl) return null;
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } on Object {
      return null;
    }
  }

  Future<void> guardarLista(String key, List<String> values) async {
    await _prefs.setString('cache_$key', jsonEncode(values));
    await _prefs.setInt(
      'cache_${key}_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
