import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// Tarjeta del sistema: superficie, radio 24 y sombra suave solo en claro.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Medidas.margen),
    this.onTap,
    this.borde,
    this.etiqueta,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Para resaltar una tarjeta que pide acción (p. ej. borde ámbar).
  final Color? borde;

  /// Texto para el lector de pantalla cuando la tarjeta es un botón.
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final caja = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        boxShadow: c.sombraTarjeta,
        border: Border.all(
          color:
              borde?.withValues(alpha: 0.45) ??
              (c.conSombra ? Colors.transparent : c.separador),
        ),
      ),
      child: child,
    );
    if (onTap == null) return caja;
    return Semantics(
      button: true,
      label: etiqueta,
      child: Presionable(onTap: onTap, escala: 0.98, child: caja),
    );
  }
}
