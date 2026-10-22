import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'asistente_screen.dart';

/// Ruta del asistente con IA ([Routes.asistente]).
final List<RouteBase> asistenteRoutes = [
  GoRoute(
    path: Routes.asistente,
    builder: (context, state) => const AsistenteScreen(),
  ),
];
