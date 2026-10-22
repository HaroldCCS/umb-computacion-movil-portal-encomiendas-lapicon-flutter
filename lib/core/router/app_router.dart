import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/asistente/asistente_routes.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/recuperar_screen.dart';
import '../../features/auth/registro_screen.dart';
import '../../features/calificaciones/calificaciones_routes.dart';
import '../../features/chat/chat_routes.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/completar_perfil_screen.dart';
import '../../features/onboarding/elegir_rol_screen.dart';
import '../../features/perfil/editar_perfil_screen.dart';
import '../../features/remitente/remitente_routes.dart';
import '../../features/session/session_controller.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/viajero/viajero_routes.dart';
import 'routes.dart';

export 'routes.dart';

/// Rutas de la app. La navegación entre login → perfil → rol → inicio la
/// decide [redirectFor] según el estado de la sesión (docs/04 §4.4).
GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        redirectFor(session.status, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.registro,
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: Routes.recuperar,
        builder: (context, state) => const RecuperarScreen(),
      ),
      GoRoute(
        path: Routes.completarPerfil,
        builder: (context, state) => const CompletarPerfilScreen(),
      ),
      GoRoute(
        path: Routes.elegirRol,
        builder: (context, state) => const ElegirRolScreen(),
      ),
      GoRoute(
        path: Routes.inicio,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: Routes.editarPerfil,
        builder: (context, state) => const EditarPerfilScreen(),
      ),
      // Cada funcionalidad aporta sus rutas (ver core/router/routes.dart).
      ...remitenteRoutes,
      ...viajeroRoutes,
      ...chatRoutes,
      ...calificacionesRoutes,
      ...asistenteRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Página no encontrada')),
    ),
  );
}

/// Regla de redirección pura (se prueba en test/router_redirect_test.dart).
String? redirectFor(SessionStatus status, String location) {
  switch (status) {
    case SessionStatus.cargando:
    case SessionStatus.error:
      return location == Routes.splash ? null : Routes.splash;
    case SessionStatus.sinSesion:
      return Routes.publicas.contains(location) ? null : Routes.login;
    case SessionStatus.sinPerfil:
      return location == Routes.completarPerfil ? null : Routes.completarPerfil;
    case SessionStatus.sinRol:
      return location == Routes.elegirRol ? null : Routes.elegirRol;
    case SessionStatus.listo:
      // Con la sesión lista no se vuelve al splash, login ni registro inicial;
      // el resto de rutas (incluidas las de cada funcionalidad) se permiten.
      final bloqueada =
          location == Routes.splash ||
          location == Routes.completarPerfil ||
          Routes.publicas.contains(location);
      return bloqueada ? Routes.inicio : null;
  }
}
