import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'icono_en_caja.dart';
import 'tarjeta.dart';

/// Tarjeta de "Vista rápida": ícono pastel, etiqueta y valor. Con [onTap]
/// lleva **directo** al lugar de la acción (docs/08 §8.4).
class Mosaico extends StatelessWidget {
  const Mosaico({
    super.key,
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.valor,
    this.onTap,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;

  /// Un `Text` o `Monto`.
  final Widget valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tarjeta(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconoEnCaja(icono, color: color),
              const Spacer(),
              if (onTap != null)
                ExcludeSemantics(
                  child: Icon(Icons.chevron_right_rounded, color: c.texto3),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(etiqueta, style: TextStyle(fontSize: 13, color: c.texto2)),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: c.texto,
              fontFeatures: cifras,
            ),
            child: valor,
          ),
        ],
      ),
    );
  }
}

/// Grilla de dos columnas; cada tarjeta toma su propio alto.
class GrillaMosaicos extends StatelessWidget {
  const GrillaMosaicos(this.hijos, {super.key});

  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, r) {
      // En Android el primer cuadro puede medir 0: sin el piso, el ancho
      // sería negativo y la lista entera dejaría de pintarse.
      final ancho = ((r.maxWidth - 12) / 2).clamp(0.0, double.infinity);
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final h in hijos) SizedBox(width: ancho, child: h)],
      );
    },
  );
}
