import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapticon_app/core/router/routes.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/accion_resaltada.dart';
import 'package:lapticon_app/core/widgets/boton.dart';
import 'package:lapticon_app/data/local/prefs.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/usuario.dart';
import 'package:lapticon_app/data/models/viaje.dart';
import 'package:lapticon_app/data/repositories/viaje_repository.dart';
import 'package:lapticon_app/features/home/home_providers.dart';
import 'package:lapticon_app/features/remitente/envios_logic.dart';
import 'package:lapticon_app/features/remitente/inicio_remitente_screen.dart';
import 'package:lapticon_app/features/remitente/remitente_providers.dart';
import 'package:lapticon_app/features/remitente/remitente_routes.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/features/viajero/mi_viaje_screen.dart';
import 'package:lapticon_app/features/viajero/viajero_local_store.dart';
import 'package:lapticon_app/features/viajero/viajero_logic.dart';
import 'package:lapticon_app/features/viajero/viajero_providers.dart';
import 'package:lapticon_app/features/viajero/viajero_routes.dart';
import 'package:lapticon_app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas de la fase 4: inicio por rol, contadores y avisos con deep link.

Encomienda _e(
  String id,
  EstadoEncomienda estado, {
  String destino = 'Miami',
  String? viajero = 'v1',
  String? remitente = 'r1',
  num valor = 20,
  String moneda = 'USD',
}) => Encomienda(
  id: id,
  ciudadOrigen: 'Bogotá',
  ciudadDestino: destino,
  observaciones: 'Regalo',
  moneda: moneda,
  valor: valor,
  estado: estado,
  viajeroUid: viajero,
  remitenteUid: remitente,
  viajeroNombre: viajero == null ? null : 'Andrés',
  remitenteNombre: 'Laura',
);

/// Repositorio de viajes que solo recuerda el cambio de estado.
class _ViajesFalsos implements ViajeRepository {
  final cambios = <(String, EstadoViaje)>[];

  @override
  Future<Viaje?> cambiarEstado(String id, EstadoViaje estado) async {
    cambios.add((id, estado));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _UsuarioFalso implements User {
  @override
  String get uid => 'r1';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Sesión sin Firebase: solo lo que leen estas pantallas.
class _SesionFalsa extends ChangeNotifier implements SessionController {
  _SesionFalsa({this.conUsuario = false});

  /// Con usuario se activan los avisos de "te la tomaron" (necesitan Prefs).
  final bool conUsuario;

  @override
  User? get user => conUsuario ? _UsuarioFalso() : null;

  @override
  Usuario? get perfil => const Usuario(
    uid: 'r1',
    nombre: 'Laura',
    apellido: 'Gómez',
    telefono: '300',
    nacionalidad: 'Colombia',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Lógica', () {
    test(
      'conNombresDeViajeros: un pedido por ruta y, si falla, sin nombre',
      () async {
        final sinNombre = [
          const Encomienda(
            id: '1',
            ciudadOrigen: 'Bogotá',
            ciudadDestino: 'Miami',
            observaciones: 'x',
            moneda: 'USD',
            valor: 1,
            estado: EstadoEncomienda.tomada,
            viajeroUid: 'v1',
          ),
          _e('2', EstadoEncomienda.disponible, viajero: null),
        ];
        final pedidos = <String>[];
        final r = await conNombresDeViajeros(sinNombre, (o, d) async {
          pedidos.add('$o→$d');
          return [
            Viaje(
              id: '',
              numeroVuelo: '',
              ciudadOrigen: o,
              ciudadDestino: d,
              fechaViaje: null,
              estado: EstadoViaje.desconocido,
              viajeroUid: 'v1',
              viajeroNombre: 'Luis Pérez',
            ),
          ];
        });
        expect(r.map((e) => e.viajeroNombre), ['Luis Pérez', null]);
        expect(pedidos, ['Bogotá→Miami']);
        final sinRed = await conNombresDeViajeros(
          sinNombre,
          (o, d) => Future.error(Exception('sin red')),
        );
        expect(sinRed.map((e) => e.viajeroNombre), [null, null]);
      },
    );

    test('sugerencias: sin mí, sin repetir, por afinidad y con nombre', () {
      final f = DateTime(2026, 12, 1);
      final r = sugerenciasParaMostrar(
        [
          (viajeroUid: 'a', afinidad: 0.5, fechaViaje: f),
          (viajeroUid: 'r1', afinidad: 0.99, fechaViaje: f),
          (viajeroUid: 'b', afinidad: 0.9, fechaViaje: f),
          (viajeroUid: 'b', afinidad: 0.8, fechaViaje: f),
          (viajeroUid: 'c', afinidad: 0.7, fechaViaje: f),
          (viajeroUid: 'd', afinidad: 0.1, fechaViaje: f),
        ],
        [
          Viaje(
            id: '',
            numeroVuelo: '',
            ciudadOrigen: 'Bogotá',
            ciudadDestino: 'Miami',
            fechaViaje: f,
            estado: EstadoViaje.disponible,
            viajeroUid: 'b',
            viajeroNombre: 'Luis Pérez',
          ),
        ],
        'r1',
      );
      expect(r.map((s) => (s.viajeroUid, s.nombre)), [
        ('b', 'Luis Pérez'),
        ('c', null),
        ('a', null),
      ]);
    });

    test('nuevas tomadas: avisa una vez y solo de lo nuevo', () {
      final a = _e('a', EstadoEncomienda.disponible, viajero: null);
      final tomadaA = _e('a', EstadoEncomienda.tomada);
      final b = _e('b', EstadoEncomienda.tomada);
      // Primera vez sin mapa: no avisa nada de golpe y guarda todo como visto.
      expect(nuevasTomadas([a, b], null), isEmpty);
      final base = actualizarVistos([a, b], null);
      expect(base, {'a': 'disponible', 'b': 'tomada'});
      // disponible → tomada: avisa; b ya se había visto tomada: no.
      expect(nuevasTomadas([tomadaA, b], base).map((e) => e.id), ['a']);
      // Mientras no la vea, sigue pendiente aunque se recargue.
      final recargado = actualizarVistos([tomadaA, b], base);
      expect(recargado, base);
      // Ya vista: no avisa más.
      expect(
        nuevasTomadas([tomadaA, b], {...recargado, 'a': 'tomada'}),
        isEmpty,
      );
      // Publicada desde otro teléfono y ya tomada: también es nueva.
      expect(
        nuevasTomadas([
          _e('c', EstadoEncomienda.tomada),
        ], base).map((e) => e.id),
        ['c'],
      );
    });

    test('ResumenEnvios cuenta y ubica lo que falta por calificar', () {
      final r = ResumenEnvios.de(
        [
          _e('1', EstadoEncomienda.tomada),
          _e('2', EstadoEncomienda.disponible, viajero: null),
          _e('3', EstadoEncomienda.entregada),
          _e('4', EstadoEncomienda.recibida),
          _e('5', EstadoEncomienda.entregada, viajero: null),
          _e('6', EstadoEncomienda.vencida),
        ],
        {'4'},
      );
      expect(r.activas, 2);
      expect(r.tomadas, 1);
      expect(r.disponibles, 1);
      expect(r.entregadas, 3);
      // La 4 ya se calificó y la 5 no tiene viajero conocido.
      expect(r.porCalificar.map((e) => e.id), ['3']);
      expect(r.nota, '1 tomada por un viajero · 1 espera viajero.');
    });

    test('ResumenEnvios sin activas invita a publicar', () {
      expect(
        ResumenEnvios.de(const [], const {}).nota,
        'No tienes envíos activos. Publica uno con el botón\u00A0+.',
      );
    });

    test('viajero: por entregar, por calificar y ganancias por moneda', () {
      final lista = [
        _e('1', EstadoEncomienda.tomada, valor: 20),
        _e('2', EstadoEncomienda.entregada, valor: 15),
        _e('3', EstadoEncomienda.recibida, remitente: null),
        _e('4', EstadoEncomienda.tomada, valor: 50000, moneda: 'cop'),
        _e('5', EstadoEncomienda.vencida, valor: 99),
      ];
      expect(porEntregar(lista).map((e) => e.id), ['1', '4']);
      expect(porCalificarViajero(lista, const {}).map((e) => e.id), ['2']);
      expect(porCalificarViajero(lista, {'2'}), isEmpty);
      expect(gananciasPorMoneda(lista), {'USD': 55, 'COP': 50000});
    });

    test('AccionPendiente viaja como ?accion= en la ruta', () {
      expect(
        AccionPendiente.calificar.en(RemitenteRoutes.detalle),
        '/remitente/encomienda?accion=calificar',
      );
      expect(
        AccionPendiente.deRuta({'accion': 'entregar'}),
        AccionPendiente.entregar,
      );
      expect(AccionPendiente.deRuta({'accion': 'otra'}), isNull);
      expect(AccionPendiente.deRuta(const {}), isNull);
    });

    test('Prefs recuerda las encomiendas calificadas por usuario', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = Prefs(await SharedPreferences.getInstance());
      expect(prefs.calificadas('u1'), isEmpty);
      await prefs.marcarCalificada('u1', 'e1');
      await prefs.marcarCalificada('u1', 'e1');
      await prefs.marcarCalificada('u1', 'e2');
      expect(prefs.calificadas('u1'), {'e1', 'e2'});
      expect(prefs.calificadas('u2'), isEmpty);
    });
  });

  testWidgets('AccionResaltada lleva hasta la acción y la explica', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light, useGoogleFonts: false),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 2000),
                AccionResaltada(
                  activa: true,
                  aviso: 'Califica al viajero.',
                  child: Text('Calificar al viajero'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Califica al viajero.'), findsOneWidget);
    // Quedó dentro de la ventana de 800×600 de la prueba.
    final visible = tester.getRect(find.text('Calificar al viajero'));
    expect(visible.top, greaterThanOrEqualTo(0));
    expect(visible.bottom, lessThanOrEqualTo(600));
  });

  /// Monta [pantalla] con go_router: el detalle muestra la ruta a la que se
  /// llegó, para comprobar los deep links.
  Future<ProviderContainer> montar(
    WidgetTester tester,
    Widget pantalla,
    List overrides, {
    SessionController? sesion,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2600)
      ..devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => pantalla),
        for (final ruta in [
          RemitenteRoutes.detalle,
          RemitenteRoutes.viajeros,
          ViajeroRoutes.encomienda,
          ViajeroRoutes.registrarViaje,
          Routes.asistente,
        ])
          GoRoute(
            path: ruta,
            builder: (_, state) => Scaffold(
              body: Text(
                'Ruta ${state.uri} · ${(state.extra as Encomienda?)?.id}',
              ),
            ),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(sesion ?? _SesionFalsa()),
          ...overrides.cast(),
        ],
        child: MaterialApp.router(
          theme: construirTema(Brightness.light, useGoogleFonts: false),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
  }

  group('Inicio del remitente', () {
    final lista = [
      _e('1', EstadoEncomienda.tomada),
      _e('2', EstadoEncomienda.disponible, viajero: null),
      _e('3', EstadoEncomienda.entregada, destino: 'Lima'),
    ];

    testWidgets('hero, aviso por calificar y vista rápida', (tester) async {
      final handle = tester.ensureSemantics();
      await montar(tester, const InicioRemitenteScreen(), [
        misEncomiendasProvider.overrideWith((ref) async => lista),
      ]);
      expect(find.text('Hola, Laura'), findsOneWidget);
      expect(find.text('Tus envíos activos'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // activas
      expect(
        find.text('1 tomada por un viajero · 1 espera viajero.'),
        findsOneWidget,
      );
      expect(find.text('TOMADAS'), findsOneWidget);
      expect(find.text('En camino'), findsNothing);
      expect(
        find.text('Tu encomienda a Lima ya fue entregada'),
        findsOneWidget,
      );
      expect(find.text('Por calificar'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('avisa cuando un viajero tomó una encomienda', (tester) async {
      SharedPreferences.setMockInitialValues({
        'remitente_estados_vistos_r1': '{"9":"disponible"}',
      });
      final prefs = Prefs(await SharedPreferences.getInstance());
      await montar(
        tester,
        const InicioRemitenteScreen(),
        sesion: _SesionFalsa(conUsuario: true),
        [
          prefsProvider.overrideWithValue(prefs),
          misEncomiendasProvider.overrideWith(
            (ref) async => [_e('9', EstadoEncomienda.tomada, destino: 'Lima')],
          ),
        ],
      );
      expect(
        find.text('¡Andrés tomó tu encomienda Bogotá → Lima!'),
        findsOneWidget,
      );
      expect(find.text('Escribirle'), findsOneWidget);
      expect(find.text('Ver envío'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.textContaining('tomó tu encomienda'), findsNothing);
      expect(prefs.estadosVistos('r1'), {'9': 'tomada'});
    });

    testWidgets('la primera vez guarda lo visto sin avisar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = Prefs(await SharedPreferences.getInstance());
      await montar(
        tester,
        const InicioRemitenteScreen(),
        sesion: _SesionFalsa(conUsuario: true),
        [
          prefsProvider.overrideWithValue(prefs),
          misEncomiendasProvider.overrideWith(
            (ref) async => [_e('9', EstadoEncomienda.tomada)],
          ),
        ],
      );
      expect(find.textContaining('tomó tu encomienda'), findsNothing);
      expect(prefs.estadosVistos('r1'), {'9': 'tomada'});
    });

    testWidgets('el aviso abre el detalle con Calificar resaltado', (
      tester,
    ) async {
      await montar(tester, const InicioRemitenteScreen(), [
        misEncomiendasProvider.overrideWith((ref) async => lista),
      ]);
      await tester.tap(find.text('Tu encomienda a Lima ya fue entregada'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ruta /remitente/encomienda?accion=calificar · 3'),
        findsOneWidget,
      );
    });

    testWidgets('los mosaicos cambian de pestaña y de chip', (tester) async {
      final contenedor = await montar(tester, const InicioRemitenteScreen(), [
        misEncomiendasProvider.overrideWith((ref) async => lista),
      ]);
      // Sin HomeShell nadie escucha la pestaña (es autoDispose).
      final sub = contenedor.listen(pestanaInicioProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.ensureVisible(find.text('Entregadas'));
      await tester.tap(find.text('Entregadas'));
      await tester.pump();
      expect(contenedor.read(pestanaInicioProvider), Pestanas.segunda);
      expect(contenedor.read(pestanaEnviosProvider), PestanaEnvios.entregadas);
    });

    testWidgets('sin envíos invita a publicar y no muestra avisos', (
      tester,
    ) async {
      await montar(tester, const InicioRemitenteScreen(), [
        misEncomiendasProvider.overrideWith((ref) async => const []),
      ]);
      expect(find.text('Aún no has enviado nada'), findsOneWidget);
      expect(find.text('Publicar encomienda'), findsOneWidget);
      expect(find.text('Por calificar'), findsNothing);
      expect(find.text('Tus envíos activos'), findsNothing);
    });
  });

  group('Mi viaje', () {
    final viaje = Viaje(
      id: 'v',
      numeroVuelo: 'AV10',
      ciudadOrigen: 'Bogotá',
      ciudadDestino: 'Miami',
      fechaViaje: DateTime(2026, 12, 1),
      estado: EstadoViaje.disponible,
    );

    List overrides(List<Encomienda> entregas) => [
      miViajeProvider.overrideWith((ref) async => viaje),
      misEntregasProvider.overrideWith((ref) async => entregas),
      historialViajesProvider.overrideWith((ref) async => [viaje]),
      viajeroLocalStoreProvider.overrideWith((ref) async {
        SharedPreferences.setMockInitialValues({});
        return ViajeroLocalStore.abrir();
      }),
    ];

    testWidgets('hero con ruta, sin insignia de vuelo y ganancias', (
      tester,
    ) async {
      await montar(
        tester,
        const MiViajeScreen(),
        overrides([_e('1', EstadoEncomienda.tomada, valor: 25)]),
      );
      expect(find.text('Bogotá → Miami'), findsWidgets);
      expect(find.text('Sin verificar'), findsNothing);
      expect(find.text('Vuelo verificado'), findsNothing);
      expect(find.text('USD 25'), findsWidgets);
      expect(find.text('Tienes una encomienda por entregar'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('HISTORIAL DE VIAJES'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('HISTORIAL DE VIAJES'), findsOneWidget);
    });

    testWidgets('el aviso abre la encomienda con Entregar resaltado', (
      tester,
    ) async {
      await montar(
        tester,
        const MiViajeScreen(),
        overrides([_e('7', EstadoEncomienda.tomada)]),
      );
      await tester.tap(find.text('Tienes una encomienda por entregar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ruta /viajero/encomienda?accion=entregar · 7'),
        findsOneWidget,
      );
    });

    testWidgets('cancelar viaje pide escribir CANCELAR y lleva a registrar', (
      tester,
    ) async {
      final repo = _ViajesFalsos();
      await montar(tester, const MiViajeScreen(), [
        ...overrides(const []),
        viajeRepositoryProvider.overrideWithValue(repo),
      ]);
      await tester.scrollUntilVisible(
        find.text('Cancelar viaje'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancelar viaje'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar tu viaje?'), findsOneWidget);
      expect(find.textContaining('Bogotá → Miami deja de aparecer'), findsOne);
      Boton confirmar() =>
          tester.widget<Boton>(find.widgetWithText(Boton, 'Sí, cancelarlo'));
      expect(confirmar().onTap, isNull);
      await tester.enterText(find.byType(TextField), 'cancelar');
      await tester.pump();
      await tester.tap(find.text('Sí, cancelarlo'));
      await tester.pumpAndSettle();

      expect(repo.cambios, [('v', EstadoViaje.cancelado)]);
      expect(find.text('Ruta /viajero/registrar-viaje · null'), findsOneWidget);
    });

    testWidgets('con encomiendas por entregar no deja cancelar', (
      tester,
    ) async {
      final repo = _ViajesFalsos();
      await montar(tester, const MiViajeScreen(), [
        ...overrides([_e('7', EstadoEncomienda.tomada)]),
        viajeRepositoryProvider.overrideWithValue(repo),
      ]);
      await tester.scrollUntilVisible(
        find.text('Cancelar viaje'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancelar viaje'));
      await tester.pumpAndSettle();
      expect(find.text('Aún llevas encomiendas'), findsOneWidget);
      expect(
        find.textContaining('Tienes una encomienda por entregar.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver por entregar'));
      await tester.pumpAndSettle();
      expect(repo.cambios, isEmpty);
      expect(
        find.text('Ruta /viajero/encomienda?accion=entregar · 7'),
        findsOneWidget,
      );
    });

    testWidgets('el historial muestra un viaje cancelado con texto e ícono', (
      tester,
    ) async {
      final cancelado = Viaje(
        id: 'c',
        numeroVuelo: 'LA2401',
        ciudadOrigen: 'Cali',
        ciudadDestino: 'Lima',
        fechaViaje: DateTime(2026, 12, 10),
        estado: EstadoViaje.parse('cancelado'),
      );
      await montar(tester, const MiViajeScreen(), [
        miViajeProvider.overrideWith((ref) async => null),
        historialViajesProvider.overrideWith((ref) async => [cancelado]),
      ]);
      await tester.scrollUntilVisible(
        find.text('Cancelado'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('sin viaje invita a registrar uno', (tester) async {
      await montar(tester, const MiViajeScreen(), [
        miViajeProvider.overrideWith((ref) async => null),
        historialViajesProvider.overrideWith((ref) async => const []),
      ]);
      expect(find.text('Aún no tienes un viaje activo'), findsOneWidget);
      expect(find.text('Registrar viaje'), findsOneWidget);
      // Sin viajes previos, el historial no aparece.
      expect(find.text('HISTORIAL DE VIAJES'), findsNothing);
    });
  });
}
