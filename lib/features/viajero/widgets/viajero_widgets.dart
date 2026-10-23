import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/insignia.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_ticket.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/encomienda.dart';
import '../../../data/models/rol.dart';
import '../../../providers.dart';

/// Tarjeta-pase de una encomienda vista por el viajero: el valor que le
/// pagan va destacado.
class EncomiendaTicket extends StatelessWidget {
  const EncomiendaTicket({super.key, required this.encomienda, this.onTap});

  final Encomienda encomienda;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = encomienda;
    return Semantics(
      label:
          'Encomienda de ${e.ciudadOrigen} a ${e.ciudadDestino}, '
          'te pagan ${Fmt.dinero(e.valor, e.moneda)}, ${e.estado.etiqueta}',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: RouteTicket(
        origen: e.ciudadOrigen,
        destino: e.ciudadDestino,
        compact: true,
        accent: Rol.viajero.accent(Theme.of(context).brightness),
        onTap: onTap,
        details: [
          TicketDetail(label: 'Te pagan', value: Fmt.dinero(e.valor, e.moneda)),
          if (e.fechaVencimiento != null)
            TicketDetail(
              label: 'Vence',
              value: Fmt.fecha(e.fechaVencimiento, corta: true),
            ),
        ],
        trailing: StatusChip.encomienda(e.estado),
      ),
    );
  }
}

/// Insignia verde "Vuelo verificado" (validado con AeroDataBox).
class VueloVerificadoBadge extends StatelessWidget {
  const VueloVerificadoBadge({super.key});

  @override
  Widget build(BuildContext context) => const Insignia(
    'Vuelo verificado',
    icono: Icons.verified,
    tipo: TipoInsignia.exito,
  );
}

/// Fila de confianza: avatar · nombre · ★ promedio (n calificaciones).
class PersonaTrustRow extends ConsumerWidget {
  const PersonaTrustRow({
    super.key,
    required this.uid,
    required this.nombre,
    required this.rolLabel,
  });

  final String uid;
  final String? nombre;
  final String rolLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final resumen = ref.watch(resumenCalificacionesProvider(uid));
    final mostrado = (nombre == null || nombre!.isEmpty) ? rolLabel : nombre!;
    final calificacion = resumen.when(
      data: (r) => r.vacio
          ? 'Sin calificaciones aún'
          : '★ ${(r.promedio ?? 0).toStringAsFixed(1).replaceAll('.', ',')} '
                '(${r.total} ${r.total == 1 ? 'calificación' : 'calificaciones'})',
      loading: () => 'Cargando calificaciones…',
      error: (_, _) => 'Calificaciones no disponibles',
    );

    return Semantics(
      label: '$rolLabel: $mostrado. $calificacion',
      excludeSemantics: true,
      child: Row(
        children: [
          Avatar(mostrado),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rolLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: c.texto2,
                  ),
                ),
                Text(
                  mostrado,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: c.texto,
                  ),
                ),
                Text(
                  calificacion,
                  style: TextStyle(fontSize: 15, color: c.texto2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenido de la hoja de confirmación para tomar una encomienda.
/// Devuelve `true` con `Navigator.pop` si la persona confirma.
class ConfirmarTomaSheet extends StatelessWidget {
  const ConfirmarTomaSheet({super.key, required this.encomienda});

  final Encomienda encomienda;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = encomienda;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Tomar esta encomienda?', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Llevarás un paquete de ${e.ciudadOrigen} a ${e.ciudadDestino} '
              'y te pagarán ${Fmt.dinero(e.valor, e.moneda)}.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Revisa el contenido antes de aceptarlo. Eres '
                      'responsable de lo que llevas en tu equipaje.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.luggage),
              label: const Text('Sí, tomarla'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección ("MIS ENTREGAS").
class SeccionHeader extends StatelessWidget {
  const SeccionHeader(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxs,
        AppSpacing.lg,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          texto.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
