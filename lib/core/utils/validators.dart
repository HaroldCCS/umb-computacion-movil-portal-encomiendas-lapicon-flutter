/// Validaciones de formularios. Devuelven `null` si el valor es válido o el
/// mensaje de error en español. Son funciones puras para poder probarlas.
abstract final class Validators {
  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$",
  );
  static final RegExp _nombre = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$");

  static String? requerido(String? value, [String campo = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$campo es obligatorio.';
    return null;
  }

  /// Fecha de nacimiento opcional (`YYYY-MM-DD`): si se elige, mayor de edad
  /// y con sentido.
  static String? fechaNacimiento(String? value, {DateTime? hoy}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final f = DateTime.tryParse(v);
    if (f == null || f.toIso8601String().substring(0, 10) != v) {
      return 'Revisa la fecha de nacimiento.';
    }
    final h = hoy ?? DateTime.now();
    var edad = h.year - f.year;
    if (h.month < f.month || (h.month == f.month && h.day < f.day)) edad--;
    if (edad < 0 || edad > 120) return 'Revisa la fecha de nacimiento.';
    if (edad < 18) return 'Debes ser mayor de edad para usar Lapticon.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu correo.';
    if (!_email.hasMatch(v)) return 'Revisa el correo: parece incompleto.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Escribe tu contraseña.';
    if (v.length < 6) return 'Usa al menos 6 caracteres.';
    return null;
  }

  static String? Function(String?) confirmarPassword(
    String Function() original,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Repite la contraseña.';
      if (value != original()) return 'Las contraseñas no coinciden.';
      return null;
    };
  }

  static String? nombre(String? value, [String campo = 'El nombre']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$campo es obligatorio.';
    if (v.length < 2) return '$campo es muy corto.';
    if (v.length > 50) return '$campo es muy largo.';
    if (!_nombre.hasMatch(v)) return '$campo solo puede tener letras.';
    return null;
  }

  static String? telefono(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s()+-]'), '');
    if (digits.isEmpty) return 'Escribe tu número de teléfono.';
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Usa solo números.';
    }
    if (digits.length < 7 || digits.length > 15) {
      return 'Debe tener entre 7 y 15 dígitos.';
    }
    return null;
  }

  /// 0 = vacía, 1 = débil, 2 = media, 3 = fuerte.
  static int fortalezaPassword(String value) {
    if (value.isEmpty) return 0;
    var puntos = 0;
    if (value.length >= 8) puntos++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      puntos++;
    }
    if (RegExp(r'\d').hasMatch(value)) puntos++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) puntos++;
    if (value.length < 6) return 1;
    return puntos <= 1 ? 1 : (puntos == 2 ? 2 : 3);
  }
}
