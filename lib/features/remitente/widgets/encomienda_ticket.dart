import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_ticket.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/encomienda.dart';
import '../../../core/theme/tema.dart';

/// Tarjeta-pase de una encomienda (FECHA · VALOR · estado).
class EncomiendaTicket extends StatelessWidget {
  const EncomiendaTicket({
    super.key,
    required this.encomienda,
    this.onTap,
    this.compact = false,
  });

  final Encomienda encomienda;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final e = encomienda;
    final vence = e.fechaVencimiento;
    return RouteTicket(
      origen: e.ciudadOrigen.isEmpty ? '—' : e.ciudadOrigen,
      destino: e.ciudadDestino.isEmpty ? '—' : e.ciudadDestino,
      compact: compact,
      // Acento del remitente: ámbar oscuro en claro para que se vea el avión.
      accent: context.c.atencion,
      onTap: onTap,
      details: [
        TicketDetail(
          label: vence != null ? 'Vence' : 'Fecha',
          value: Fmt.fecha(vence ?? e.creadaEn, corta: true),
        ),
        TicketDetail(label: 'Valor', value: Fmt.dinero(e.valor, e.moneda)),
      ],
      trailing: StatusChip.encomienda(e.estado),
    );
  }
}
