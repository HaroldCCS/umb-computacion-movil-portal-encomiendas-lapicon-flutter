import 'package:flutter/material.dart';

import '../theme/tema.dart';

/// Bloque gris con brillo que se desplaza: anticipa la forma del contenido
/// mientras carga. Con "reducir movimiento" queda quieto.
class Esqueleto extends StatefulWidget {
  const Esqueleto({super.key, this.alto = 20, this.ancho, this.radio = 12});

  final double alto;
  final double? ancho;
  final double radio;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final x = 3 * _ctrl.value - 1;
          return Container(
            height: widget.alto,
            width: widget.ancho,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radio),
              gradient: LinearGradient(
                begin: Alignment(-1 + x - 1, 0),
                end: Alignment(1 + x - 1, 0),
                colors: [c.superficie2, c.separador, c.superficie2],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lista de [cantidad] bloques con forma de tarjeta (por defecto, del alto
/// de una tarjeta-pase). Se anuncia como "Cargando".
class EsqueletoLista extends StatelessWidget {
  const EsqueletoLista({
    super.key,
    this.cantidad = 3,
    this.alto = 168,
    this.primero,
  });

  final int cantidad;
  final double alto;

  /// Alto de un primer bloque distinto (p. ej. la tarjeta principal).
  final double? primero;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primero != null) ...[
          Esqueleto(alto: primero!, radio: Medidas.radioHero),
          const SizedBox(height: Medidas.bloque),
        ],
        for (var i = 0; i < cantidad; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Esqueleto(alto: alto, radio: Medidas.radioTarjeta),
        ],
      ],
    ),
  );
}
