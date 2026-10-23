import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tema.dart';
import '../../../core/widgets/aviso.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/hoja.dart';
import '../../../core/widgets/insignia.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_ticket.dart';
import '../../../data/models/encomienda.dart';
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
        accent: context.c.viajero,
        onTap: onTap,
        details: [
          TicketDetail(label: 'Te pagan', value: Fmt.dinero(e.valor, e.moneda)),
          if (e.fechaVencimiento != null)
            TicketDetail(
              label: 'Vence',
              value: Fmt.fecha(e.fechaVencimiento, corta: true),
            ),
        ],
        trailing: Insignia.encomienda(e.estado),
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
          const SizedBox(width: 12),
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

/// Hoja para confirmar que se toma una encomienda. El recordatorio de
/// responsabilidad se muestra completo, en una caja visible (docs/08 §8.5).
/// Devuelve `true` solo si la persona confirma.
Future<bool> confirmarToma(BuildContext context, Encomienda e) =>
    confirmarConHoja(
      context,
      titulo: '¿Tomar esta encomienda?',
      mensaje:
          'Llevarás un paquete de ${e.ciudadOrigen} a ${e.ciudadDestino} y '
          'te pagarán ${Fmt.dinero(e.valor, e.moneda)}.',
      detalle: const Aviso(
        'Revisa el contenido antes de aceptarlo. Eres responsable de lo que '
        'llevas en tu equipaje.',
        titulo: 'Antes de aceptar',
        tipo: TipoAviso.atencion,
      ),
      confirmarTexto: 'Sí, tomarla',
      cancelarTexto: 'Cancelar',
    );
