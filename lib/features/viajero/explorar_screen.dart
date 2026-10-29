import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/viaje.dart';
import 'mi_viaje_screen.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';
import 'viajero_routes.dart';
import 'widgets/viajero_widgets.dart';

/// Pestaña "Explorar": encomiendas disponibles en la ruta de mi viaje, con
/// lo que pagan a la vista.
class ExplorarScreen extends ConsumerStatefulWidget {
  const ExplorarScreen({super.key});

  @override
  ConsumerState<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends ConsumerState<ExplorarScreen> {
  var _orden = OrdenExplorar.recientes;

  Future<void> _refrescar() async {
    ref.invalidate(miViajeProvider);
    ref.invalidate(disponiblesEnMiRutaProvider);
    try {
      await ref.read(disponiblesEnMiRutaProvider.future);
    } on Object {
      // El error se muestra en la propia pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final miViaje = ref.watch(miViajeProvider);
    final viaje = miViaje.value;
    final disponibles = ref.watch(disponiblesEnMiRutaProvider);
    final hayVarias = (disponibles.value?.length ?? 0) > 1;

    return Pantalla(
      titulo: 'Explorar',
      subtitulo: viaje == null ? null : 'Encomiendas que van por tu ruta.',
      conBarraPestanas: true,
      alActualizar: _refrescar,
      accion: BotonIcono(
        icono: Icons.support_agent,
        etiqueta: 'Asistente',
        borde: false,
        onTap: () => context.push(Routes.asistente),
      ),
      cabecera: viaje != null && hayVarias
          ? Chips<OrdenExplorar>(
              opciones: [
                for (final o in OrdenExplorar.values) (o, o.titulo, null),
              ],
              valor: _orden,
              onCambio: (o) => setState(() => _orden = o),
            )
          : null,
      hijos: switch (miViaje) {
        AsyncData(value: final v?) => _conViaje(v, disponibles),
        AsyncData() => [
          Vacio(
            titulo: 'Primero registra tu viaje',
            icono: Icons.luggage_outlined,
            texto:
                'Te mostraremos las encomiendas que van por tu misma ruta y lo '
                'que pagan por llevarlas.',
            accion: Boton(
              'Registrar viaje',
              icono: Icons.flight_takeoff,
              onTap: () => context.push(ViajeroRoutes.registrarViaje),
            ),
          ),
        ],
        AsyncError(:final error) => [
          ErrorCarga(
            mensaje: error is AppException
                ? error.message
                : 'No pudimos cargar tu viaje.',
            alReintentar: () => ref.invalidate(miViajeProvider),
          ),
        ],
        _ => [const EsqueletoLista()],
      },
    );
  }

  List<Widget> _conViaje(Viaje viaje, AsyncValue<List<Encomienda>> lista) {
    final c = context.c;
    final ruta = RouteTicket(
      origen: viaje.ciudadOrigen,
      destino: viaje.ciudadDestino,
      compact: true,
      accent: c.viajero,
      details: [
        TicketDetail(
          label: 'Tu vuelo',
          value: viaje.numeroVuelo.isEmpty ? '—' : viaje.numeroVuelo,
        ),
        TicketDetail(
          label: 'Fecha',
          value: Fmt.fecha(viaje.fechaViaje, corta: true),
        ),
      ],
    );
    // Las que tomé van aparte y arriba, para no confundirlas con las
    // disponibles (docs/11 §2G).
    final llevo = porEntregar(ref.watch(misEntregasProvider).value ?? const []);
    final lasQueLlevo = [
      if (llevo.isNotEmpty)
        Semantics(
          header: true,
          child: Text('Las que llevas', style: context.t.titleLarge),
        ),
      for (final e in llevo)
        EncomiendaTicket(
          encomienda: e,
          onTap: () => abrirEncomiendaViajero(context, e),
        ),
    ];
    return switch (lista) {
      AsyncData(:final value) when value.isEmpty => [
        ruta,
        ...lasQueLlevo,
        const Vacio(
          titulo: 'Aún no hay encomiendas para esta ruta',
          icono: Icons.inbox_outlined,
          texto: 'Desliza hacia abajo para actualizar más tarde.',
        ),
      ],
      AsyncData(:final value) => [
        ruta,
        ...lasQueLlevo,
        Semantics(
          header: true,
          child: Text(
            '${value.length} '
            '${value.length == 1 ? 'encomienda disponible' : 'encomiendas disponibles'}',
            style: context.t.titleLarge,
          ),
        ),
        for (final e in ordenarDisponibles(value, _orden))
          EncomiendaTicket(
            encomienda: e,
            onTap: () => abrirEncomiendaViajero(context, e),
          ),
      ],
      AsyncError(:final error) => [
        ruta,
        ...lasQueLlevo,
        Aviso(
          error is AppException
              ? error.message
              : 'No pudimos cargar las encomiendas.',
          tipo: TipoAviso.error,
          accion: Boton(
            'Reintentar',
            chico: true,
            ancho: false,
            variante: VarianteBoton.secundario,
            onTap: () => ref.invalidate(disponiblesEnMiRutaProvider),
          ),
        ),
      ],
      _ => [ruta, ...lasQueLlevo, const EsqueletoLista(cantidad: 2)],
    };
  }
}
