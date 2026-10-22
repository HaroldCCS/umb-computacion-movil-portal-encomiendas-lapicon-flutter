import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../data/models/resumen_calificaciones.dart';
import '../../providers.dart';
import 'star_rating.dart';

/// Argumentos de [ResenasScreen] (ruta [ResenasScreen.path]).
class ResenasArgs {
  const ResenasArgs({required this.uid, this.nombre});

  final String uid;
  final String? nombre;
}

/// Reseñas recibidas por un usuario (`GET /api/ratings/:uid`, pública).
class ResenasScreen extends ConsumerWidget {
  const ResenasScreen({super.key, required this.args});

  static const path = '/calificaciones/usuario';

  final ResenasArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = args;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calificaciones')),
        body: const EmptyState(
          icon: Icons.star_outline_rounded,
          title: 'No encontramos a esta persona',
          message: 'Vuelve atrás e inténtalo de nuevo.',
        ),
      );
    }
    final resumen = ref.watch(resumenCalificacionesProvider(a.uid));
    final titulo = (a.nombre?.isNotEmpty ?? false)
        ? 'Calificaciones de ${a.nombre}'
        : 'Calificaciones';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: resumen.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is AppException
              ? e.message
              : 'No pudimos cargar las calificaciones.',
          onRetry: () => ref.invalidate(resumenCalificacionesProvider(a.uid)),
        ),
        data: (r) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(resumenCalificacionesProvider(a.uid).future),
          child: r.vacio
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: AppSpacing.xxl),
                    EmptyState(
                      icon: Icons.star_outline_rounded,
                      title: 'Aún no hay calificaciones',
                      message: 'Aparecerán aquí después de la primera entrega.',
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _Resumen(resumen: r),
                    const SizedBox(height: AppSpacing.lg),
                    for (final c in r.calificaciones) ...[
                      _CalificacionTile(calificacion: c),
                      const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Cuántas calificaciones hay de cada puntaje (índice 1..5).
List<int> distribucion(List<Calificacion> calificaciones) {
  final conteo = List<int>.filled(6, 0);
  for (final c in calificaciones) {
    if (c.calificacion >= 1 && c.calificacion <= 5) conteo[c.calificacion]++;
  }
  return conteo;
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.resumen});

  final ResumenCalificaciones resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promedio = resumen.promedio ?? 0;
    final conteo = distribucion(resumen.calificaciones);
    final maximo = conteo.skip(1).fold<int>(0, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              promedio.toStringAsFixed(1).replaceAll('.', ','),
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 48),
            ),
            StarRating(value: promedio),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${resumen.total} '
              '${resumen.total == 1 ? 'calificación' : 'calificaciones'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            children: [
              for (var estrellas = 5; estrellas >= 1; estrellas--)
                Semantics(
                  label:
                      '$estrellas estrellas: ${conteo[estrellas]} '
                      '${conteo[estrellas] == 1 ? 'calificación' : 'calificaciones'}',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$estrellas',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maximo == 0
                                  ? 0
                                  : conteo[estrellas] / maximo,
                              minHeight: 8,
                              color: theme.colorScheme.secondary,
                              backgroundColor: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${conteo[estrellas]}',
                            style: theme.textTheme.labelMedium,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalificacionTile extends StatelessWidget {
  const _CalificacionTile({required this.calificacion});

  final Calificacion calificacion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = Fmt.relativo(calificacion.fecha);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(value: calificacion.calificacion.toDouble()),
              const Spacer(),
              if (fecha.isNotEmpty)
                Text(
                  fecha,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            calificacion.comentario.isEmpty
                ? 'Sin comentario.'
                : calificacion.comentario,
            style: calificacion.comentario.isEmpty
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  )
                : theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
