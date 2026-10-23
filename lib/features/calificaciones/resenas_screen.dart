import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/grupo.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/progreso.dart';
import '../../core/widgets/tarjeta.dart';
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
      return const Pantalla(
        titulo: 'Calificaciones',
        hijos: [
          Vacio(
            titulo: 'No encontramos a esta persona',
            icono: Icons.star_outline_rounded,
            texto: 'Vuelve atrás e inténtalo de nuevo.',
          ),
        ],
      );
    }
    final resumen = ref.watch(resumenCalificacionesProvider(a.uid));
    final titulo = (a.nombre?.isNotEmpty ?? false)
        ? 'Calificaciones de ${a.nombre}'
        : 'Calificaciones';

    return Pantalla(
      titulo: titulo,
      alActualizar: () async {
        try {
          ref.invalidate(resumenCalificacionesProvider(a.uid));
          await ref.read(resumenCalificacionesProvider(a.uid).future);
        } on Object {
          // El error se muestra en la propia pantalla.
        }
      },
      hijos: switch (resumen) {
        AsyncData(value: final r) when r.vacio => const [
          Vacio(
            titulo: 'Aún no hay calificaciones',
            icono: Icons.star_outline_rounded,
            texto: 'Aparecerán aquí después de la primera entrega.',
          ),
        ],
        AsyncData(value: final r) => [
          Tarjeta(child: _Resumen(resumen: r)),
          Grupo(
            titulo: 'Reseñas',
            hijos: [
              for (final c in r.calificaciones)
                _CalificacionTile(calificacion: c),
            ],
          ),
        ],
        AsyncError(:final error) => [
          ErrorCarga(
            mensaje: error is AppException
                ? error.message
                : 'No pudimos cargar las calificaciones.',
            alReintentar: () =>
                ref.invalidate(resumenCalificacionesProvider(a.uid)),
          ),
        ],
        _ => [const EsqueletoLista(primero: 150, cantidad: 3, alto: 80)],
      },
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
    final c = context.c;
    final promedio = resumen.promedio ?? 0;
    final conteo = distribucion(resumen.calificaciones);
    final maximo = conteo.skip(1).fold<int>(0, (a, b) => a > b ? a : b);

    return Row(
      children: [
        Column(
          children: [
            Text(
              promedio.toStringAsFixed(1).replaceAll('.', ','),
              style: context.t.displayLarge?.copyWith(
                fontSize: 48,
                color: c.texto,
              ),
            ),
            const SizedBox(height: 4),
            StarRating(value: promedio),
            const SizedBox(height: 4),
            Text(
              '${resumen.total} '
              '${resumen.total == 1 ? 'calificación' : 'calificaciones'}',
              style: TextStyle(fontSize: 13, color: c.texto2),
            ),
          ],
        ),
        const SizedBox(width: 20),
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
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$estrellas',
                            style: TextStyle(fontSize: 13, color: c.texto2),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Pastel.ambar,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Progreso(
                            maximo == 0 ? 0 : conteo[estrellas] / maximo,
                            alto: 8,
                            color: Pastel.ambar,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${conteo[estrellas]}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.texto2,
                              fontFeatures: cifras,
                            ),
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
    final c = context.c;
    final fecha = Fmt.relativo(calificacion.fecha);
    final sinComentario = calificacion.comentario.isEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(value: calificacion.calificacion.toDouble()),
              const Spacer(),
              if (fecha.isNotEmpty)
                Text(fecha, style: TextStyle(fontSize: 13, color: c.texto2)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sinComentario ? 'Sin comentario.' : calificacion.comentario,
            style: TextStyle(
              fontSize: sinComentario ? 15 : 17,
              height: 1.35,
              color: sinComentario ? c.texto2 : c.texto,
              fontStyle: sinComentario ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }
}
