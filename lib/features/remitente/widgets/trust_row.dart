import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../providers.dart';

/// Avatar con iniciales · nombre · ★ promedio (total) — docs/07 §7.5.
class TrustRow extends ConsumerWidget {
  const TrustRow({
    super.key,
    required this.uid,
    this.nombre,
    this.rolEtiqueta = 'Viajero',
    this.trailing,
  });

  final String uid;
  final String? nombre;
  final String rolEtiqueta;
  final Widget? trailing;

  static String iniciales(String? nombre, String fallback) {
    final partes = (nombre ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    if (partes.isEmpty) return fallback.substring(0, 1).toUpperCase();
    return partes
        .map((p) => String.fromCharCode(p.runes.first).toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumen = ref.watch(resumenCalificacionesProvider(uid));
    final mostrado = (nombre?.trim().isNotEmpty ?? false)
        ? nombre!.trim()
        : rolEtiqueta;

    final calificacion = resumen.when(
      loading: () => 'Cargando calificaciones…',
      error: (_, _) => 'Sin calificaciones disponibles',
      data: (r) => r.vacio
          ? 'Aún sin calificaciones'
          : '★ ${(r.promedio ?? 0).toStringAsFixed(1).replaceAll('.', ',')} '
                '(${r.total} ${r.total == 1 ? 'reseña' : 'reseñas'})',
    );

    return Semantics(
      label: '$rolEtiqueta: $mostrado. $calificacion',
      excludeSemantics: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              iniciales(nombre, rolEtiqueta),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostrado,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  calificacion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
