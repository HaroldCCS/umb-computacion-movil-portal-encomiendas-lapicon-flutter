import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Logotipo: avión sobre el degradado Medianoche + "Lapticon" en
/// Space Grotesk.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: 'Lapticon',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: Degradados.remitente,
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: size * 0.55,
              color: c.remitente,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Lapticon',
            style: context.t.displaySmall?.copyWith(
              fontSize: size * 0.6,
              letterSpacing: -0.3,
              color: c.texto,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador "Paso X de Y" para el registro inicial.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: 'Paso $step de $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASO $step DE $total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: c.texto2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step ? c.marca : c.superficie2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < total) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
