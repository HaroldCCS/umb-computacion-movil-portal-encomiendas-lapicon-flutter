/// Formatos en español sin depender de la carga de datos de `intl`
/// (así también funcionan en pruebas unitarias).
abstract final class Fmt {
  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// `1 dic 2026` (o `1 dic` si es del año actual y [corta]).
  static String fecha(DateTime? d, {bool corta = false}) {
    if (d == null) return '—';
    final base = '${d.day} ${_meses[d.month - 1]}';
    if (corta && d.year == DateTime.now().year) return base;
    return '$base ${d.year}';
  }

  /// `USD 10`, `COP 50.000`, `USD 12,50`.
  static String dinero(num valor, String moneda) {
    final entero = valor.truncate();
    final decimales = ((valor - entero).abs() * 100).round();
    final miles = entero.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final signo = valor < 0 ? '-' : '';
    final dec = decimales == 0
        ? ''
        : ',${decimales.toString().padLeft(2, '0')}';
    return '${moneda.toUpperCase()} $signo$miles$dec';
  }

  /// "hace 5 min", "hace 2 h", "ayer", o la fecha.
  static String relativo(DateTime? d, {DateTime? ahora}) {
    if (d == null) return '';
    final now = ahora ?? DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    return fecha(d, corta: true);
  }

  /// `14:05`.
  static String hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
