import 'package:flutter/material.dart';

import '../../core/theme/tema.dart';

/// Estrellas de solo lectura con lectura accesible del valor.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 18});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Ámbar de los íconos pastel: se ve igual sobre claro y oscuro.
    const color = Pastel.ambar;
    return Semantics(
      label: '${value.toStringAsFixed(1).replaceAll('.', ',')} de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              value >= i
                  ? Icons.star_rounded
                  : (value >= i - 0.5
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
              color: color,
              size: size,
            ),
        ],
      ),
    );
  }
}
