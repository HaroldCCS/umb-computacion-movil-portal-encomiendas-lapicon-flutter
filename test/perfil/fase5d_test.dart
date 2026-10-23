import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapticon_app/core/network/app_exception.dart';
import 'package:lapticon_app/core/router/routes.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/boton.dart';
import 'package:lapticon_app/core/widgets/toast.dart';
import 'package:lapticon_app/data/local/prefs.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/data/models/usuario.dart';
import 'package:lapticon_app/data/repositories/calificaciones_repository.dart';
import 'package:lapticon_app/data/repositories/chatbot_repository.dart';
import 'package:lapticon_app/features/asistente/asistente_screen.dart';
import 'package:lapticon_app/features/calificaciones/calificar_screen.dart';
import 'package:lapticon_app/features/calificaciones/resenas_screen.dart';
import 'package:lapticon_app/features/chat/chat_providers.dart';
import 'package:lapticon_app/features/chat/conversaciones_screen.dart';
import 'package:lapticon_app/features/chat/models/conversacion.dart';
import 'package:lapticon_app/features/chat/widgets/compositor_mensaje.dart';
import 'package:lapticon_app/features/perfil/perfil_screen.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas de la fase 5d: chat, calificaciones, perfil y asistente.

class _Usuario implements User {
  @override
  String get uid => 'yo';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Sesion extends ChangeNotifier implements SessionController {
  bool cerro = false;

  @override
  User? get user => _Usuario();

  @override
  Usuario? get perfil => const Usuario(
    uid: 'yo',
    nombre: 'Laura',
    apellido: 'Gómez',
    telefono: '3001234567',
    nacionalidad: 'Colombia',
  );

  @override
  Rol? get rol => Rol.remitente;

  @override
  String? get email => 'laura@prueba.co';

  @override
  bool get rolEnServidor => false;

  @override
  Future<void> cerrarSesion() async => cerro = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CalificacionesFalla implements CalificacionesRepository {
  @override
  Future<void> calificar({
    required String usuarioDestino,
    required Rol rolDestino,
    required int calificacion,
    String comentario = '',
    String? encomiendaId,
  }) => Future.error(const NetworkException('Sin conexión.'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ChatbotCaido implements ChatbotRepository {
  @override
  Future<String> enviar(String mensajeUsuario) =>
      Future.error(const ApiException(500, 'El asistente no respondió.'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _resumen = ResumenCalificaciones(
  total: 2,
  promedio: 4.5,
  calificaciones: [],
);

Future<_Sesion> _montar(
  WidgetTester tester,
  Widget pantalla, {
  List extra = const [],
  Brightness brillo = Brightness.light,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = Prefs(await SharedPreferences.getInstance());
  final sesion = _Sesion();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(child: Boton('abrir', onTap: () => context.push('/p'))),
        ),
      ),
      GoRoute(path: '/p', builder: (_, _) => pantalla),
      GoRoute(
        path: Routes.chat,
        builder: (_, state) => Scaffold(
          body: Text('Chat con ${(state.extra as ChatArgs).otroNombre}'),
        ),
      ),
      for (final r in [Routes.editarPerfil, ResenasScreen.path])
        GoRoute(path: r, builder: (_, _) => const Scaffold()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(sesion),
        prefsProvider.overrideWithValue(prefs),
        resumenCalificacionesProvider.overrideWith(
          (ref, uid) async => _resumen,
        ),
        ...extra.cast(),
      ],
      child: MaterialApp.router(
        theme: construirTema(brillo, useGoogleFonts: false),
        builder: (context, hijo) => Toasts(child: hijo!),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return sesion;
}

void main() {
  group('Compositor', () {
    Widget app(Widget hijo) => MaterialApp(
      theme: construirTema(Brightness.light, useGoogleFonts: false),
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: hijo),
      ),
    );

    testWidgets('envía, limpia y anuncia el botón', (tester) async {
      final handle = tester.ensureSemantics();
      final enviados = <String>[];
      await tester.pumpWidget(
        app(
          CompositorMensaje(
            onEnviar: (t) async {
              enviados.add(t);
              return true;
            },
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Enviar mensaje')),
        isSemantics(isButton: true, isEnabled: false),
      );
      await tester.enterText(find.byType(TextField), '  Hola  ');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(enviados, ['Hola']);
      expect(find.text('  Hola  '), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cerrado no deja escribir y explica por qué', (tester) async {
      await tester.pumpWidget(
        app(CompositorMensaje(cerrado: true, onEnviar: (_) async => true)),
      );
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text('Este chat se cerró porque la entrega terminó.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Conversaciones: fila con ruta y abre el chat', (tester) async {
    await _montar(
      tester,
      const ConversacionesScreen(),
      extra: [
        conversacionesProvider.overrideWith(
          (ref, uid) => Stream.value([
            Conversacion(
              id: 'c1',
              participantes: const ['yo', 'v1'],
              nombres: const {'yo': 'Laura', 'v1': 'Andrés Ruiz'},
              ruta: 'Bogota → Miami',
              ultimoMensaje: '¿Nos vemos en el aeropuerto?',
              ultimoEmisorUid: 'v1',
              actualizadoEn: DateTime.now(),
            ),
          ]),
        ),
      ],
    );
    expect(find.text('Andrés Ruiz'), findsOneWidget);
    expect(find.text('BOGOTA → MIAMI'), findsOneWidget);
    expect(find.text('¿Nos vemos en el aeropuerto?'), findsOneWidget);
    await tester.tap(find.text('Andrés Ruiz'));
    await tester.pumpAndSettle();
    expect(find.text('Chat con Andrés Ruiz'), findsOneWidget);
  });

  group('Calificar', () {
    const args = CalificarArgs(
      usuarioDestino: 'v1',
      rolDestino: Rol.viajero,
      nombreDestino: 'Andrés',
    );

    testWidgets('pide estrellas, sugiere y muestra el error junto al botón', (
      tester,
    ) async {
      await _montar(
        tester,
        const CalificarScreen(args: args),
        extra: [
          calificacionesRepositoryProvider.overrideWithValue(
            _CalificacionesFalla(),
          ),
        ],
      );
      expect(find.text('¿Cómo te fue con Andrés?'), findsOneWidget);
      Boton enviar() => tester.widget<Boton>(
        find.widgetWithText(Boton, 'Enviar calificación'),
      );
      expect(enviar().onTap, isNull);

      await tester.tap(find.bySemanticsLabel('5 de 5 estrellas'));
      await tester.pumpAndSettle();
      expect(find.text('Excelente'), findsOneWidget);
      await tester.tap(find.text('Puntual'));
      await tester.pump();
      expect(enviar().onTap, isNotNull);

      await tester.ensureVisible(find.text('Enviar calificación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar calificación'));
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión.'), findsOneWidget);
    });

    testWidgets('sin nombre usa la contraparte del rol', (tester) async {
      await _montar(
        tester,
        const CalificarScreen(
          args: CalificarArgs(usuarioDestino: 'r1', rolDestino: Rol.remitente),
        ),
      );
      expect(find.text('¿Cómo te fue con el remitente?'), findsOneWidget);
    });
  });

  testWidgets('Reseñas: promedio y barras por estrella', (tester) async {
    await _montar(
      tester,
      const ResenasScreen(
        args: ResenasArgs(uid: 'v1', nombre: 'Andrés'),
      ),
    );
    expect(find.text('Calificaciones de Andrés'), findsWidgets);
    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('2 calificaciones'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('5 estrellas: 0')), findsOneWidget);
  });

  group('Perfil', () {
    testWidgets('datos, rol y cuenta estilo ajustes', (tester) async {
      final handle = tester.ensureSemantics();
      await _montar(tester, const PerfilScreen());
      expect(find.text('Laura Gómez'), findsOneWidget);
      expect(find.text('laura@prueba.co'), findsOneWidget);
      expect(find.bySemanticsLabel('Rol actual: Remitente'), findsOneWidget);
      expect(find.text('4,5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cambiar a viajero'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Tu rol está guardado en este teléfono.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('cerrar sesión se confirma en una hoja', (tester) async {
      final sesion = await _montar(tester, const PerfilScreen());
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      await tester.tap(find.text('No, seguir aquí'));
      await tester.pumpAndSettle();
      expect(sesion.cerro, isFalse);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, cerrar sesión'));
      await tester.pumpAndSettle();
      expect(sesion.cerro, isTrue);
    });

    for (final brillo in Brightness.values) {
      testWidgets('cumple contraste ($brillo)', (tester) async {
        final handle = tester.ensureSemantics();
        await _montar(tester, const PerfilScreen(), brillo: brillo);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('Asistente', () {
    testWidgets('sugerencias al inicio y error con Reintentar', (tester) async {
      await _montar(
        tester,
        const AsistenteScreen(),
        extra: [chatbotRepositoryProvider.overrideWithValue(_ChatbotCaido())],
      );
      expect(find.text('¿En qué te ayudo?'), findsOneWidget);
      final sugerencia = sugerenciasAsistente(Rol.remitente).first;
      await tester.tap(find.text(sugerencia));
      await tester.pumpAndSettle();
      expect(find.text(sugerencia), findsOneWidget); // ahora como burbuja
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
