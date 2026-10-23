import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Barra de progreso que se anima al aparecer (0..1).
class Progreso extends StatelessWidget {
  const Progreso(
    this.valor, {
    super.key,
    this.alto = 6,
    this.fondo,
    this.color,
    this.degradado,
  });

  final double valor;
  final double alto;
  final Color? fondo;
  final Color? color;
  final Gradient? degradado;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final v = valor.clamp(0.0, 1.0);
    return Semantics(
      value: '${(v * 100).round()} %',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(alto),
        child: Container(
          height: alto,
          color: fondo ?? c.superficie2,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v),
            duration: Movimiento.duracion(context, Movimiento.lento),
            curve: Curves.easeOut,
            builder: (_, x, _) => FractionallySizedBox(
              // Un mínimo visible para que 0 % no parezca "sin barra".
              widthFactor: x.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: degradado == null ? (color ?? c.marca) : null,
                  gradient: degradado,
                  borderRadius: BorderRadius.circular(alto),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
