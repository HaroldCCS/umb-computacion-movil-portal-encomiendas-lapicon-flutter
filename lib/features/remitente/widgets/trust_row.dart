import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tema.dart';
import '../../../core/widgets/avatar.dart';
import '../../../providers.dart';

/// Avatar con iniciales (color estable por persona) · nombre · ★ promedio (total) — docs/07 §7.5.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
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
          Avatar(mostrado),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostrado,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: c.texto,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  calificacion,
                  style: TextStyle(fontSize: 15, color: c.texto2),
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
