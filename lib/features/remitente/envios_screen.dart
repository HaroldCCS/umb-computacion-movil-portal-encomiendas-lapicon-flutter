import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/feedback_views.dart';
import '../../data/models/encomienda.dart';
import 'envios_logic.dart';
import 'remitente_providers.dart';
import 'remitente_routes.dart';
import 'widgets/encomienda_ticket.dart';

/// Pestaña "Envíos" del remitente: mis encomiendas agrupadas por estado.
class EnviosScreen extends ConsumerWidget {
  const EnviosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final envios = ref.watch(misEncomiendasProvider);

    return DefaultTabController(
      length: PestanaEnvios.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis envíos'),
          actions: [
            IconButton(
              tooltip: 'Asistente',
              icon: const Icon(Icons.support_agent),
              onPressed: () => context.push(Routes.asistente),
            ),
          ],
          bottom: TabBar(
            tabs: [for (final p in PestanaEnvios.values) Tab(text: p.titulo)],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab-nueva-encomienda',
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          onPressed: () => abrirNuevaEncomienda(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nueva encomienda'),
        ),
        body: envios.when(
          loading: () => const TabBarView(
            children: [_Skeleton(), _Skeleton(), _Skeleton()],
          ),
          error: (e, _) => ErrorView(
            message: e is AppException
                ? e.message
                : 'No pudimos cargar tus envíos.',
            onRetry: () => ref.invalidate(misEncomiendasProvider),
          ),
          data: (lista) {
            final grupos = agruparEnvios(lista);
            return TabBarView(
              children: [
                for (final p in PestanaEnvios.values)
                  _ListaEnvios(pestana: p, encomiendas: grupos[p]!),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Abre "Nueva encomienda" y refresca la lista al volver si se publicó.
Future<void> abrirNuevaEncomienda(BuildContext context, WidgetRef ref) async {
  final creada = await context.push<bool>(RemitenteRoutes.nuevaEncomienda);
  if (creada == true) ref.invalidate(misEncomiendasProvider);
}

class _ListaEnvios extends ConsumerWidget {
  const _ListaEnvios({required this.pestana, required this.encomiendas});

  final PestanaEnvios pestana;
  final List<Encomienda> encomiendas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refrescar() async {
      ref.invalidate(misEncomiendasProvider);
      try {
        await ref.read(misEncomiendasProvider.future);
      } on Object {
        // El error se muestra en la vista principal.
      }
    }

    if (encomiendas.isEmpty) {
      final (titulo, mensaje) = switch (pestana) {
        PestanaEnvios.activas => (
          'Aún no has enviado nada',
          'Publica tu primera encomienda y encuentra quién la lleve.',
        ),
        PestanaEnvios.entregadas => (
          'Sin entregas todavía',
          'Cuando un viajero entregue tu encomienda, aparecerá aquí.',
        ),
        PestanaEnvios.historial => (
          'Historial vacío',
          'Aquí verás las encomiendas canceladas o vencidas.',
        ),
      };
      return RefreshIndicator(
        onRefresh: refrescar,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: titulo,
                message: mensaje,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.amberDark
                    : AppColors.estadoTomada,
                actionLabel: pestana == PestanaEnvios.activas
                    ? 'Publicar encomienda'
                    : null,
                onAction: pestana == PestanaEnvios.activas
                    ? () => abrirNuevaEncomienda(context, ref)
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refrescar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Espacio inferior para que el FAB no tape la última tarjeta.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          96,
        ),
        itemCount: encomiendas.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final e = encomiendas[i];
          return EncomiendaTicket(
            encomienda: e,
            onTap: () async {
              final cambio = await context.push<bool>(
                RemitenteRoutes.detalle,
                extra: e,
              );
              if (cambio == true) ref.invalidate(misEncomiendasProvider);
            },
          );
        },
      ),
    );
  }
}

/// Esqueleto de carga: 3 tarjetas grises (docs/07 §7.7).
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Cargando tus envíos',
      excludeSemantics: true,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
        ],
      ),
    );
  }
}
