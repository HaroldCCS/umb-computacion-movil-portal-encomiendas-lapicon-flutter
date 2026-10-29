import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/pantalla.dart';
import '../../data/models/encomienda.dart';
import '../calificaciones/calificaciones_providers.dart';
import 'envios_logic.dart';
import 'remitente_providers.dart';
import 'remitente_routes.dart';
import 'widgets/aviso_tomada.dart';
import 'widgets/encomienda_ticket.dart';

/// Pestaña "Envíos" del remitente: mis encomiendas agrupadas por estado en
/// chips (Activas · Entregadas · Historial). El contador de "Entregadas"
/// son las que faltan por calificar.
class EnviosScreen extends ConsumerWidget {
  const EnviosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envios = ref.watch(misEncomiendasProvider);
    final pestana = ref.watch(pestanaEnviosProvider);
    escucharEstadosVistos(ref);
    final calificadas = calificadasDe(ref);

    Future<void> refrescar() async {
      ref.invalidate(misEncomiendasProvider);
      try {
        await ref.read(misEncomiendasProvider.future);
      } on Object {
        // El error se muestra en la propia pantalla.
      }
    }

    final grupos = switch (envios) {
      AsyncData(:final value) => agruparEnvios(value),
      _ => null,
    };
    final porCalificar = switch (envios) {
      AsyncData(:final value) => ResumenEnvios.de(
        value,
        calificadas,
      ).porCalificar.length,
      _ => 0,
    };

    return Pantalla(
      titulo: 'Mis envíos',
      conBarraPestanas: true,
      alActualizar: refrescar,
      cabecera: Chips<PestanaEnvios>(
        opciones: [
          for (final p in PestanaEnvios.values)
            (p, p.titulo, p == PestanaEnvios.entregadas ? porCalificar : null),
        ],
        valor: pestana,
        onCambio: ref.read(pestanaEnviosProvider.notifier).ir,
      ),
      hijos: switch (envios) {
        AsyncError(:final error) => [
          ErrorCarga(
            mensaje: error is AppException
                ? error.message
                : 'No pudimos cargar tus envíos.',
            alReintentar: () => ref.invalidate(misEncomiendasProvider),
          ),
        ],
        _ when grupos == null => [const EsqueletoLista()],
        _ when grupos[pestana]!.isEmpty => [_vacio(context, ref, pestana)],
        _ => [
          if (nuevasTomadasDe(ref).isNotEmpty) const AvisosTomadas(),
          for (final e in grupos[pestana]!)
            EncomiendaTicket(
              encomienda: e,
              onTap: () => abrirDetalleEnvio(context, ref, e),
            ),
        ],
      },
    );
  }

  Widget _vacio(BuildContext context, WidgetRef ref, PestanaEnvios pestana) {
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
        'Aquí verás las encomiendas que retiraste o que vencieron.',
      ),
    };
    return Vacio(
      titulo: titulo,
      icono: Icons.inventory_2_outlined,
      texto: mensaje,
      accion: pestana == PestanaEnvios.activas
          ? Boton(
              'Publicar encomienda',
              icono: Icons.add_rounded,
              onTap: () => abrirNuevaEncomienda(context, ref),
            )
          : null,
    );
  }
}

/// Abre "Nueva encomienda" y refresca la lista al volver si se publicó.
Future<void> abrirNuevaEncomienda(BuildContext context, WidgetRef ref) async {
  final creada = await context.push<bool>(RemitenteRoutes.nuevaEncomienda);
  if (creada == true) ref.invalidate(misEncomiendasProvider);
}

/// Abre el detalle (con [accion] resaltada si viene de un aviso) y refresca
/// la lista al volver si cambió.
Future<void> abrirDetalleEnvio(
  BuildContext context,
  WidgetRef ref,
  Encomienda e, {
  AccionPendiente? accion,
}) async {
  final ruta = accion?.en(RemitenteRoutes.detalle) ?? RemitenteRoutes.detalle;
  final cambio = await context.push<bool>(ruta, extra: e);
  if (cambio == true) ref.invalidate(misEncomiendasProvider);
}
