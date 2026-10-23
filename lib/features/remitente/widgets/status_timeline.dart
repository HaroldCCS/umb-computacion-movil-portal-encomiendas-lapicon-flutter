import 'package:flutter/material.dart';

import '../../../core/theme/tema.dart';
import '../../../data/models/estado.dart';
import '../envios_logic.dart';

/// Línea de tiempo vertical: Publicada → Tomada → Entregada → Calificada.
/// Vencida (o retirada por el remitente) se muestra como estado final (docs/07 §7.5).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.estado,
    this.calificada = false,
  });

  final EstadoEncomienda estado;
  final bool calificada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.c;
    final actual = pasoActual(estado, calificada: calificada);

    if (actual == null) {
      return Semantics(
        label: 'Estado final: ${estado.etiqueta}',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(Icons.event_busy, color: c.texto2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estado == EstadoEncomienda.vencida
                    ? 'Ya no está publicada: venció o la retiraste.'
                    : 'No conocemos el estado de esta encomienda.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    final hecho = c.exito;
    final muted = c.separador;
    return Column(
      children: [
        for (var i = 0; i < pasosEncomienda.length; i++)
          Semantics(
            label:
                '${pasosEncomienda[i]}: ${i < actual
                    ? 'completado'
                    : i == actual
                    ? 'paso actual'
                    : 'pendiente'}',
            excludeSemantics: true,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Icon(
                          i < actual
                              ? Icons.check_circle
                              : i == actual
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 24,
                          color: i <= actual ? hecho : muted,
                        ),
                        if (i < pasosEncomienda.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: i < actual ? hecho : muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        pasosEncomienda[i],
                        style: i == actual
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyLarge?.copyWith(
                                color: i < actual ? c.texto : c.texto2,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
