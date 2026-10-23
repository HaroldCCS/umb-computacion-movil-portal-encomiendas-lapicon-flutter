import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'aviso.dart';

/// Envuelve las acciones de un detalle. Cuando se llega desde un aviso
/// ("Califica al viajero"), [activa] es `true`: al abrir, la pantalla se
/// desplaza hasta aquí y muestra [aviso] encima del botón (docs/08 §8.4).
class AccionResaltada extends StatefulWidget {
  const AccionResaltada({
    super.key,
    required this.activa,
    required this.aviso,
    required this.child,
  });

  final bool activa;
  final String aviso;
  final Widget child;

  @override
  State<AccionResaltada> createState() => _AccionResaltadaState();
}

class _AccionResaltadaState extends State<AccionResaltada> {
  @override
  void initState() {
    super.initState();
    if (!widget.activa) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.8,
        duration: Movimiento.duracion(context, Movimiento.normal),
        curve: Movimiento.entrada,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.activa) ...[
        Aviso(widget.aviso, tipo: TipoAviso.atencion),
        const SizedBox(height: 12),
      ],
      widget.child,
    ],
  );
}
