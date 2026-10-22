import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/rol.dart';
import '../../data/models/viaje.dart';
import '../../providers.dart';
import 'viajero_providers.dart';
import 'viajero_routes.dart';
import 'widgets/viajero_widgets.dart';

/// Pestaña "Mi viaje": viaje activo, mis entregas e historial.
class MiViajeScreen extends ConsumerWidget {
  const MiViajeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miViaje = ref.watch(miViajeProvider);
    final sinViaje = switch (miViaje) {
      AsyncData(:final value) => value == null,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi viaje'),
        actions: [
          IconButton(
            tooltip: 'Asistente',
            icon: const Icon(Icons.support_agent),
            onPressed: () => context.push(Routes.asistente),
          ),
        ],
      ),
      floatingActionButton: sinViaje
          ? FloatingActionButton.extended(
              onPressed: () => context.push(ViajeroRoutes.registrarViaje),
              icon: const Icon(Icons.flight_takeoff),
              label: const Text('Registrar viaje'),
            )
          : null,
      body: miViaje.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is AppException ? e.message : 'Intenta de nuevo.',
          onRetry: () => ref.invalidate(miViajeProvider),
        ),
        data: (viaje) =>
            viaje == null ? const _SinViaje() : _ConViaje(viaje: viaje),
      ),
    );
  }
}

class _SinViaje extends StatelessWidget {
  const _SinViaje();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.flight_takeoff,
            title: 'Aún no tienes un viaje activo',
            message:
                'Registra tu vuelo para ver encomiendas de tu ruta y ganar '
                'llevándolas.',
            color: Rol.viajero.accent(Theme.of(context).brightness),
          ),
        ),
        const Padding(
          // Deja espacio para el botón flotante.
          padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 88),
          child: _HistorialTile(),
        ),
      ],
    );
  }
}

class _ConViaje extends ConsumerWidget {
  const _ConViaje({required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(sessionProvider).user?.uid;
    final verificado = switch (ref.watch(viajeroLocalStoreProvider)) {
      AsyncData(:final value) =>
        uid != null &&
            value.vueloVerificado(uid, viaje.numeroVuelo, viaje.fechaViaje),
      _ => false,
    };
    final entregas = ref.watch(misEntregasProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refrescarViajero(ref);
        try {
          await ref.read(miViajeProvider.future);
        } on Object {
          // El error se muestra en la propia vista.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          RouteTicket(
            origen: viaje.ciudadOrigen,
            destino: viaje.ciudadDestino,
            accent: Rol.viajero.accent(theme.brightness),
            details: [
              TicketDetail(
                label: 'Vuelo',
                value: viaje.numeroVuelo.isEmpty ? '—' : viaje.numeroVuelo,
              ),
              TicketDetail(
                label: 'Fecha',
                value: Fmt.fecha(viaje.fechaViaje, corta: true),
              ),
            ],
            trailing: StatusChip.viaje(viaje.estado),
          ),
          if (verificado) ...[
            const SizedBox(height: AppSpacing.sm),
            const Align(
              alignment: Alignment.centerLeft,
              child: VueloVerificadoBadge(),
            ),
          ],
          const SeccionHeader('Mis entregas'),
          entregas.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _Aviso(
              texto: e is AppException
                  ? e.message
                  : 'No pudimos cargar tus entregas.',
              accion: 'Reintentar',
              onAccion: () => ref.invalidate(misEntregasProvider),
            ),
            data: (lista) => lista.isEmpty
                ? const _Aviso(
                    texto:
                        'Aún no has tomado encomiendas. Revisa la pestaña '
                        'Explorar para ver las de tu ruta.',
                  )
                : Column(
                    children: [
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
          ),
          const SizedBox(height: AppSpacing.md),
          const _HistorialTile(),
        ],
      ),
    );
  }
}

/// Historial de viajes, colapsado por defecto.
class _HistorialTile extends ConsumerWidget {
  const _HistorialTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historial = ref.watch(historialViajesProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      // Material propio: el ListTile pinta su tinta encima del fondo.
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.history),
          title: const Text('Historial de viajes'),
          subtitle: historial.when(
            data: (l) => Text(
              l.isEmpty
                  ? 'Sin viajes registrados'
                  : '${l.length} ${l.length == 1 ? 'viaje' : 'viajes'}',
            ),
            loading: () => const Text('Cargando…'),
            error: (_, _) => const Text('No disponible'),
          ),
          children: historial.when(
            data: (lista) => [
              for (final v in lista)
                ListTile(
                  leading: Icon(
                    Icons.flight,
                    color: Rol.viajero.accent(theme.brightness),
                  ),
                  title: Text('${v.ciudadOrigen} → ${v.ciudadDestino}'),
                  subtitle: Text(
                    '${v.numeroVuelo.isEmpty ? 'Vuelo' : v.numeroVuelo} · '
                    '${Fmt.fecha(v.fechaViaje)}',
                  ),
                  trailing: StatusChip.viaje(v.estado),
                ),
            ],
            loading: () => const [LinearProgressIndicator()],
            error: (e, _) => [
              ListTile(
                title: Text(
                  e is AppException
                      ? e.message
                      : 'No pudimos cargar el historial.',
                ),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(historialViajesProvider),
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.accion, this.onAccion});

  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (accion != null && onAccion != null)
            TextButton(onPressed: onAccion, child: Text(accion!)),
        ],
      ),
    );
  }
}
