import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/aviso.dart';
import '../../../core/widgets/boton.dart';
import '../../../data/models/encomienda.dart';
import '../../../providers.dart';
import '../envios_screen.dart';
import '../remitente_providers.dart';

/// Avisos de "¡Un viajero tomó tu encomienda…!" (docs/11 §2G): van arriba en
/// Inicio y Envíos hasta que el remitente abre el detalle o toca "Entendido".
/// Lo visto se guarda al cargar la lista (ver `HomeShell`).
class AvisosTomadas extends ConsumerWidget {
  const AvisosTomadas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void marcar(Iterable<Encomienda> vistas) {
      final uid = ref.read(sessionProvider).user?.uid;
      if (uid != null) {
        ref.read(estadosVistosProvider(uid).notifier).marcarVistas(vistas);
      }
    }

    final nuevas = nuevasTomadasDe(ref);
    if (nuevas.isEmpty) return const SizedBox.shrink();
    if (nuevas.length > 2) {
      return Aviso(
        'Escríbeles por chat para coordinar la entrega.',
        titulo: '¡Viajeros tomaron ${nuevas.length} de tus encomiendas!',
        tipo: TipoAviso.exito,
        accion: Boton(
          'Entendido',
          chico: true,
          ancho: false,
          variante: VarianteBoton.secundario,
          onTap: () => marcar(nuevas),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in nuevas.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _AvisoTomada(e: e, alVer: () => marcar([e])),
        ],
      ],
    );
  }
}

class _AvisoTomada extends ConsumerWidget {
  const _AvisoTomada({required this.e, required this.alVer});

  final Encomienda e;
  final VoidCallback alVer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quien = e.viajeroNombre ?? 'Un viajero';
    final viajero = e.viajeroUid;
    return Aviso(
      'Coordinen por chat dónde y cuándo se la entregas.',
      titulo:
          '¡$quien tomó tu encomienda ${e.ciudadOrigen} → ${e.ciudadDestino}!',
      tipo: TipoAviso.exito,
      accion: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Boton(
            'Escribirle',
            icono: Icons.chat_bubble_outline,
            chico: true,
            ancho: false,
            onTap: viajero == null
                ? null
                : () {
                    alVer();
                    context.push(
                      Routes.chat,
                      extra: ChatArgs(
                        otroUid: viajero,
                        otroNombre: e.viajeroNombre,
                        encomienda: e,
                      ),
                    );
                  },
          ),
          Boton(
            'Ver envío',
            chico: true,
            ancho: false,
            variante: VarianteBoton.secundario,
            onTap: () => abrirDetalleEnvio(context, ref, e),
          ),
          Boton(
            'Entendido',
            chico: true,
            ancho: false,
            variante: VarianteBoton.secundario,
            onTap: alVer,
          ),
        ],
      ),
    );
  }
}
