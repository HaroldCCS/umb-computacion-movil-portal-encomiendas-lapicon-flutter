import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/encomienda.dart';
import 'encomienda_viajero_screen.dart';
import 'registrar_viaje_screen.dart';

/// Rutas del viajero (prefijo `/viajero/`, ver core/router/routes.dart).
abstract final class ViajeroRoutes {
  static const registrarViaje = '/viajero/registrar-viaje';

  /// Detalle de encomienda para el viajero. `extra`: [Encomienda].
  static const encomienda = '/viajero/encomienda';
}

final List<RouteBase> viajeroRoutes = [
  GoRoute(
    path: ViajeroRoutes.registrarViaje,
    builder: (context, state) => const RegistrarViajeScreen(),
  ),
  GoRoute(
    path: ViajeroRoutes.encomienda,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Encomienda) {
        return EncomiendaViajeroScreen(encomienda: extra);
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No encontramos esa encomienda.')),
      );
    },
  ),
];
