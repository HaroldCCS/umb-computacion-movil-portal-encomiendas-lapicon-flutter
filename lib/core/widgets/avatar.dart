import 'package:flutter/material.dart';

/// Iniciales con un color estable por persona (el tono sale del nombre).
/// Es decorativo: el nombre siempre aparece al lado.
class Avatar extends StatelessWidget {
  const Avatar(this.nombre, {super.key, this.tam = 44});

  final String nombre;
  final double tam;

  /// "Laura Gómez" → "LG"; "laura" → "L"; vacío → "?".
  static String iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    final primera = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primera + ultima).toUpperCase();
  }

  /// Tono entre 0 y 359, siempre el mismo para el mismo nombre.
  static int tono(String nombre) {
    var h = 0;
    for (final r in nombre.trim().toLowerCase().runes) {
      h = (h * 31 + r) % 360;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final h = tono(nombre).toDouble();
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = HSLColor.fromAHSL(
      1,
      h,
      oscuro ? .30 : .65,
      oscuro ? .24 : .90,
    ).toColor();
    final frente = HSLColor.fromAHSL(
      1,
      h,
      oscuro ? .70 : .55,
      oscuro ? .78 : .28,
    ).toColor();
    return ExcludeSemantics(
      child: Container(
        width: tam,
        height: tam,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Text(
          iniciales(nombre),
          textScaler: TextScaler.noScaling, // el círculo no crece
          style: TextStyle(
            fontSize: tam * 0.38,
            fontWeight: FontWeight.w600,
            color: frente,
          ),
        ),
      ),
    );
  }
}
