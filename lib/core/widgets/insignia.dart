import 'package:flutter/material.dart';

import '../../data/models/estado.dart';
import '../theme/tema.dart';

enum TipoInsignia { exito, atencion, peligro, info, neutra }

/// Estado en píldora: color + **ícono** + texto, nunca solo color
/// (docs/07 §7.3-2). Reemplaza a `StatusChip`.
class Insignia extends StatelessWidget {
  const Insignia(
    this.texto, {
    super.key,
    this.icono,
    this.tipo = TipoInsignia.neutra,
    this.semantica,
  });

  factory Insignia.encomienda(EstadoEncomienda estado, {Key? key}) {
    final (icono, tipo) = switch (estado) {
      EstadoEncomienda.disponible => (Icons.schedule, TipoInsignia.info),
      EstadoEncomienda.tomada => (Icons.luggage, TipoInsignia.atencion),
      EstadoEncomienda.entregada => (Icons.check_circle, TipoInsignia.exito),
      EstadoEncomienda.recibida => (Icons.done_all, TipoInsignia.exito),
      EstadoEncomienda.vencida => (Icons.event_busy, TipoInsignia.neutra),
      EstadoEncomienda.desconocido => (Icons.help_outline, TipoInsignia.neutra),
    };
    return Insignia(
      estado.etiqueta,
      key: key,
      icono: icono,
      tipo: tipo,
      semantica: 'Estado: ${estado.etiqueta}',
    );
  }

  factory Insignia.viaje(EstadoViaje estado, {Key? key}) {
    final (icono, tipo) = switch (estado) {
      EstadoViaje.disponible => (Icons.flight_takeoff, TipoInsignia.info),
      EstadoViaje.completado => (Icons.flight_land, TipoInsignia.neutra),
      EstadoViaje.desconocido => (Icons.help_outline, TipoInsignia.neutra),
    };
    return Insignia(
      estado.etiqueta,
      key: key,
      icono: icono,
      tipo: tipo,
      semantica: 'Estado: ${estado.etiqueta}',
    );
  }

  final String texto;
  final IconData? icono;
  final TipoInsignia tipo;

  /// Lo que lee el lector de pantalla (por defecto, [texto]).
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (fondo, frente) = switch (tipo) {
      TipoInsignia.exito => (c.exitoSuave, c.exito),
      TipoInsignia.atencion => (c.atencionSuave, c.atencion),
      TipoInsignia.peligro => (c.peligroSuave, c.peligro),
      TipoInsignia.info => (c.infoSuave, c.info),
      TipoInsignia.neutra => (c.superficie2, c.texto2),
    };
    return Semantics(
      label: semantica ?? texto,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 15, color: frente),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: frente,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
