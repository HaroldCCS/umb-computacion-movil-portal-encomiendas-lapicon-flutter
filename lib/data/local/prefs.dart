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
