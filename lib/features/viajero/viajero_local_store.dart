import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/encomienda.dart';
import 'viajero_logic.dart';

/// Registro local del viajero en este teléfono:
/// - encomiendas que tomé (no hay endpoint de "mis entregas"), y
/// - vuelos que se verificaron con AeroDataBox (para la insignia).
class ViajeroLocalStore {
  ViajeroLocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<ViajeroLocalStore> abrir() async =>
      ViajeroLocalStore(await SharedPreferences.getInstance());

  String _kEntregas(String uid) => 'viajero_entregas_$uid';
  String _kVuelos(String uid) => 'viajero_vuelos_verificados_$uid';

  List<Encomienda> entregas(String uid) {
    final raw = _prefs.getString(_kEntregas(uid));
    if (raw == null) return const [];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.values.whereType<Map>().map(Encomienda.fromJson).toList();
    } on Object {
      return const [];
    }
  }

  Set<String> idsEntregas(String uid) => {for (final e in entregas(uid)) e.id};

  /// Agrega o actualiza una encomienda tomada.
  Future<void> guardarEntrega(String uid, Encomienda e) async {
    final actuales = {for (final x in entregas(uid)) x.id: x};
    actuales[e.id] = e;
    await _prefs.setString(
      _kEntregas(uid),
      jsonEncode({for (final x in actuales.values) x.id: encomiendaToJson(x)}),
    );
  }

  bool vueloVerificado(String uid, String numero, DateTime? fecha) =>
      (_prefs.getStringList(_kVuelos(uid)) ?? const []).contains(
        claveVuelo(numero, fecha),
      );

  Future<void> marcarVueloVerificado(
    String uid,
    String numero,
    DateTime fecha,
  ) async {
    final lista = {...?_prefs.getStringList(_kVuelos(uid))}
      ..add(claveVuelo(numero, fecha));
    await _prefs.setStringList(_kVuelos(uid), lista.toList());
  }
}
