import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'calificar_screen.dart';
import 'resenas_screen.dart';

/// Rutas de calificaciones (Práctica 6).
/// - [Routes.calificar] con `extra: CalificarArgs` → devuelve `true` al calificar.
/// - [ResenasScreen.path] con `extra: ResenasArgs` → reseñas recibidas.
final List<RouteBase> calificacionesRoutes = [
  GoRoute(
    path: Routes.calificar,
    builder: (context, state) {
      final extra = state.extra;
      return CalificarScreen(args: extra is CalificarArgs ? extra : null);
    },
  ),
  GoRoute(
    path: ResenasScreen.path,
    builder: (context, state) {
      final extra = state.extra;
      return ResenasScreen(args: extra is ResenasArgs ? extra : null);
    },
  ),
];
