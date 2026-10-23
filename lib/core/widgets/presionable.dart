import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tema.dart';

/// Respuesta táctil de toda la app: sin onda de Material, una escala corta
/// (docs/08 §8.2). Sin [onTap] se ve atenuado y no responde.
class Presionable extends StatefulWidget {
  const Presionable({
    super.key,
    required this.child,
    this.onTap,
    this.escala = 0.97,
    this.haptico = false,
    this.atenuarInactivo = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double escala;
  final bool haptico;

  /// Sin [onTap] se atenúa al 40 %. Un botón que está cargando pasa `false`
  /// para seguir viéndose activo mientras no responde.
  final bool atenuarInactivo;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _abajo = false;

  void _set(bool v) {
    if (_abajo != v) setState(() => _abajo = v);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.onTap != null;
    final duracion = Movimiento.duracion(context, Movimiento.rapido);
    // La acción de toque para el lector de pantalla la da este Semantics;
    // así funciona aunque un ancestro use `excludeSemantics`.
    return Semantics(
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: activo ? (_) => _set(true) : null,
        onTapUp: activo ? (_) => _set(false) : null,
        onTapCancel: activo ? () => _set(false) : null,
        onTap: activo
            ? () {
                if (widget.haptico) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _abajo ? widget.escala : 1,
          duration: duracion,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: activo
                ? (_abajo ? 0.85 : 1)
                : (widget.atenuarInactivo ? 0.4 : 1),
            duration: duracion,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
