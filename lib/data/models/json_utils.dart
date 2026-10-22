/// Utilidades para leer JSON del backend de forma tolerante, porque el
/// contrato exacto de algunas respuestas aún no está confirmado.
library;

/// Si el objeto viene envuelto (p. ej. `{ "usuario": {...} }`), lo desenvuelve.
Map<String, dynamic>? unwrapObject(dynamic json, List<String> keys) {
  if (json is! Map) return null;
  final map = Map<String, dynamic>.from(json);
  for (final key in keys) {
    final inner = map[key];
    if (inner is Map) return Map<String, dynamic>.from(inner);
  }
  return map;
}

/// Si la lista viene envuelta (p. ej. `{ "data": [...] }`), la desenvuelve.
List<dynamic> unwrapList(dynamic json, List<String> keys) {
  if (json is List) return json;
  if (json is Map) {
    for (final key in keys) {
      final inner = json[key];
      if (inner is List) return inner;
    }
  }
  return const [];
}

String readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}

num? readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? readDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
