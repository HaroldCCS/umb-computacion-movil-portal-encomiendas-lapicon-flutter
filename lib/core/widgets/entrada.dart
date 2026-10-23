import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Aparece con fade + 10 px hacia arriba. [indice] escalona listas
/// (40 ms por ítem, máximo 8). Con "reducir movimiento" no se anima.
class Entrada extends StatelessWidget {
  const Entrada({super.key, required this.child, this.indice = 0});

  final Widget child;
  final int indice;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final retraso = 40 * indice.clamp(0, 8);
    final total = Movimiento.normal.inMilliseconds + retraso;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(retraso / total, 1, curve: Movimiento.entrada),
      builder: (_, v, hijo) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}
