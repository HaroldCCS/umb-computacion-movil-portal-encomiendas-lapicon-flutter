import 'package:flutter/material.dart';

/// Recuadro pastel con ícono ("Vista rápida"). El fondo es el color al 14 %.
/// Es decorativo: el texto de al lado dice lo que significa.
class IconoEnCaja extends StatelessWidget {
  const IconoEnCaja(
    this.icono, {
    super.key,
    required this.color,
    this.tam = 44,
  });

  final IconData icono;
  final Color color;
  final double tam;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(tam * 0.32),
      ),
      child: Icon(icono, color: color, size: tam * 0.5),
    ),
  );
}
