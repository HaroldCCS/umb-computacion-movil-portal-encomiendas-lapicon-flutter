import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/encomienda.dart';
import '../../core/router/routes.dart';
import 'buscar_viajeros_screen.dart';
import 'encomienda_detalle_screen.dart';
import 'nueva_encomienda_screen.dart';

/// Rutas propias del remitente (prefijo `/remitente`).
abstract final class RemitenteRoutes {
  /// Formulario de nueva encomienda. Al cerrar devuelve `true` si se publicó.
  static const nuevaEncomienda = '/remitente/nueva-encomienda';

  /// Detalle. `extra`: [Encomienda]. Al cerrar devuelve `true` si cambió.
  /// Con `?accion=calificar` abre con esa acción resaltada.
  static const detalle = '/remitente/encomienda';

  /// Buscar viajeros por ciudad (se abre desde "Vista rápida").
  static const viajeros = '/remitente/viajeros';
}

final List<RouteBase> remitenteRoutes = [
  GoRoute(
    path: RemitenteRoutes.viajeros,
    builder: (context, state) => const BuscarViajerosScreen(),
  ),
  GoRoute(
    path: RemitenteRoutes.nuevaEncomienda,
    builder: (context, state) => const NuevaEncomiendaScreen(),
  ),
  GoRoute(
    path: RemitenteRoutes.detalle,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Encomienda) {
        return EncomiendaDetalleScreen(
          encomienda: extra,
          accion: AccionPendiente.deRuta(state.uri.queryParameters),
        );
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No encontramos esta encomienda.')),
      );
    },
  ),
];
