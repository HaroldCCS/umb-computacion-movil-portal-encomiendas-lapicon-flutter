import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/rol.dart';
import '../../data/models/viaje.dart';
import 'viajero_providers.dart';
import 'viajero_routes.dart';
import 'widgets/viajero_widgets.dart';

/// Pestaña "Explorar": encomiendas disponibles en la ruta de mi viaje.
class ExplorarScreen extends ConsumerWidget {
  const ExplorarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miViaje = ref.watch(miViajeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomiendas para tu ruta'),
        actions: [
          IconButton(
            tooltip: 'Asistente',
            icon: const Icon(Icons.support_agent),
            onPressed: () => context.push(Routes.asistente),
          ),
        ],
      ),
      body: miViaje.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is AppException ? e.message : 'Intenta de nuevo.',
          onRetry: () => ref.invalidate(miViajeProvider),
        ),
        data: (viaje) => viaje == null
            ? EmptyState(
                icon: Icons.luggage_outlined,
                title: 'Primero registra tu viaje',
                message:
                    'Te mostraremos las encomiendas que van por tu misma '
                    'ruta y lo que pagan por llevarlas.',
                actionLabel: 'Registrar viaje',
                onAction: () => context.push(ViajeroRoutes.registrarViaje),
                color: Rol.viajero.accent(Theme.of(context).brightness),
              )
            : _Disponibles(viaje: viaje),
      ),
    );
  }
}

class _Disponibles extends ConsumerWidget {
  const _Disponibles({required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final disponibles = ref.watch(disponiblesEnMiRutaProvider);

    final cabecera = <Widget>[
      RouteTicket(
        origen: viaje.ciudadOrigen,
        destino: viaje.ciudadDestino,
        compact: true,
        accent: Rol.viajero.accent(theme.brightness),
        details: [
          TicketDetail(label: 'Tu vuelo', value: viaje.numeroVuelo),
          TicketDetail(
            label: 'Fecha',
            value: Fmt.fecha(viaje.fechaViaje, corta: true),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(disponiblesEnMiRutaProvider);
        try {
          await ref.read(disponiblesEnMiRutaProvider.future);
        } on Object {
          // El error se muestra en la vista.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ...cabecera,
          ...disponibles.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      e is AppException
                          ? e.message
                          : 'No pudimos cargar las encomiendas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.invalidate(disponiblesEnMiRutaProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
            data: (lista) => lista.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Aún no hay encomiendas para esta ruta.',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Desliza hacia abajo para actualizar más tarde.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ]
                : [
                    SeccionHeader(
                      '${lista.length} '
                      '${lista.length == 1 ? 'encomienda disponible' : 'encomiendas disponibles'}',
                    ),
                    for (final e in lista) ...[
                      EncomiendaTicket(
                        encomienda: e,
                        onTap: () =>
                            context.push(ViajeroRoutes.encomienda, extra: e),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
          ),
        ],
      ),
    );
  }
}
