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
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/viaje.dart';
import 'package:lapticon_app/data/repositories/encomienda_repository.dart';
import 'package:lapticon_app/data/repositories/viaje_repository.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/features/viajero/encomienda_viajero_screen.dart';
import 'package:lapticon_app/features/viajero/explorar_screen.dart';
import 'package:lapticon_app/features/viajero/registrar_viaje_screen.dart';
import 'package:lapticon_app/features/viajero/viajero_local_store.dart';
import 'package:lapticon_app/features/viajero/viajero_logic.dart';
import 'package:lapticon_app/features/viajero/viajero_providers.dart';
import 'package:lapticon_app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas de la fase 5c: explorar, registrar viaje y encomienda del viajero.

class _UsuarioFalso implements User {
  @override
  String get uid => 'yo';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SesionFalsa extends ChangeNotifier implements SessionController {
  @override
  User? get user => _UsuarioFalso();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EncomiendasFalsas implements EncomiendaRepository {
  _EncomiendasFalsas({this.busqueda = const BusquedaEncomiendas()});

  final BusquedaEncomiendas busqueda;
  String? tomada;
  EstadoEncomienda? nuevoEstado;
  final rutasBuscadas = <String>[];

  @override
  Future<BusquedaEncomiendas> buscar({
    required String origen,
    required String destino,
  }) async {
    rutasBuscadas.add('$origen→$destino');
    return busqueda;
  }

  @override
  Future<Encomienda?> tomar(String id) async {
    tomada = id;
    return null;
  }

  @override
  Future<Encomienda?> cambiarEstado(String id, EstadoEncomienda estado) async {
    nuevoEstado = estado;
    return null;
  }

  @override
  Future<List<Encomienda>> mias() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ViajesFalsos implements ViajeRepository {
  _ViajesFalsos({this.errorCrear});

  final ApiException? errorCrear;

  @override
  Future<Map<String, dynamic>> validarVuelo(String numero, DateTime fecha) =>
      // Como hoy en el backend compartido: /api/vuelos responde 500.
      Future.error(const ApiException(500, 'Error interno'));

  @override
  Future<Viaje> crear({
    required String numeroVuelo,
    required String ciudadOrigen,
    required String ciudadDestino,
    required DateTime fechaViaje,
  }) async {
    if (errorCrear != null) throw errorCrear!;
    return _viaje;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _viaje = Viaje(
  id: 'v',
  numeroVuelo: 'AV10',
  ciudadOrigen: 'Bogota',
  ciudadDestino: 'Miami',
  fechaViaje: DateTime(2026, 12, 1),
  estado: EstadoViaje.disponible,
);

Encomienda _e(
  String id,
  EstadoEncomienda estado, {
  String destino = 'Miami',
  DateTime? creada,
  DateTime? vence,
  String? viajero,
}) => Encomienda(
  id: id,
  ciudadOrigen: 'Bogota',
  ciudadDestino: destino,
  observaciones: 'Dos libros',
  moneda: 'USD',
  valor: 30,
  estado: estado,
  remitenteUid: 'r1',
  remitenteNombre: 'Laura',
  viajeroUid: viajero,
  creadaEn: creada,
  fechaVencimiento: vence,
);

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  List extra = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = Prefs(await SharedPreferences.getInstance());
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(child: Boton('abrir', onTap: () => context.push('/p'))),
        ),
      ),
      GoRoute(path: '/p', builder: (_, _) => pantalla),
      for (final ruta in [Routes.asistente, Routes.chat, Routes.calificar])
        GoRoute(path: ruta, builder: (_, _) => const Scaffold()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(_SesionFalsa()),
        prefsProvider.overrideWithValue(prefs),
        ciudadesProvider.overrideWith((ref) async => ['Bogota', 'Miami']),
        viajeroLocalStoreProvider.overrideWith(
          (ref) => ViajeroLocalStore.abrir(),
        ),
        resumenCalificacionesProvider.overrideWith(
          (ref, uid) async => const ResumenCalificaciones(
            total: 1,
            promedio: 5,
            calificaciones: [],
          ),
        ),
        ...extra.cast(),
      ],
      child: MaterialApp.router(
        theme: construirTema(Brightness.light, useGoogleFonts: false),
        builder: (context, hijo) => Toasts(child: hijo!),
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto).last);
  await tester.pumpAndSettle();
}

void main() {
  test('ordenarDisponibles por recientes o por vencimiento', () {
    final a = _e(
      'a',
      EstadoEncomienda.disponible,
      creada: DateTime(2026, 10, 1),
      vence: DateTime(2026, 11, 1),
    );
    final b = _e(
      'b',
      EstadoEncomienda.disponible,
      creada: DateTime(2026, 10, 10),
      vence: DateTime(2026, 11, 20),
    );
    final c = _e('c', EstadoEncomienda.disponible);
    expect(
      ordenarDisponibles([a, c, b], OrdenExplorar.recientes).map((e) => e.id),
      ['b', 'a', 'c'],
    );
    expect(
      ordenarDisponibles([
        b,
        c,
        a,
      ], OrdenExplorar.vencenPronto).map((e) => e.id),
      ['a', 'b', 'c'],
    );
  });

  group('buscar en mi ruta (docs/11 §2B)', () {
    test(
      'Explorar sin las propias; Mis entregas = tomadas + teléfono',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = await ViajeroLocalStore.abrir();
        // Entregada desde este teléfono: buscar ya no la trae.
        await store.guardarEntrega(
          'yo',
          _e('l1', EstadoEncomienda.entregada, viajero: 'yo'),
        );
        const propia = Encomienda(
          id: 'mia',
          ciudadOrigen: 'Bogota',
          ciudadDestino: 'Miami',
          observaciones: 'x',
          moneda: 'USD',
          valor: 5,
          estado: EstadoEncomienda.disponible,
          remitenteUid: 'yo',
        );
        final repo = _EncomiendasFalsas(
          busqueda: BusquedaEncomiendas(
            disponibles: [propia, _e('otra', EstadoEncomienda.disponible)],
            tomadas: [_e('t1', EstadoEncomienda.tomada, viajero: 'yo')],
          ),
        );
        final c = ProviderContainer(
          overrides: [
            sessionProvider.overrideWithValue(_SesionFalsa()),
            miViajeProvider.overrideWith((ref) async => _viaje),
            encomiendaRepositoryProvider.overrideWithValue(repo),
            viajeroLocalStoreProvider.overrideWith((ref) async => store),
          ],
        );
        addTearDown(c.dispose);
        final disponibles = c.listen(disponiblesEnMiRutaProvider, (_, _) {});
        final entregas = c.listen(misEntregasProvider, (_, _) {});
        addTearDown(disponibles.close);
        addTearDown(entregas.close);

        expect(
          (await c.read(disponiblesEnMiRutaProvider.future)).map((e) => e.id),
          ['otra'],
        );
        final mias = await c.read(misEntregasProvider.future);
        expect(mias.map((e) => e.id), ['t1', 'l1']);
        expect(mias.first.remitenteUid, 'r1');
        // Explorar y Mis entregas comparten una sola búsqueda.
        expect(repo.rutasBuscadas, ['Bogota→Miami']);
      },
    );
  });

  group('Explorar', () {
    testWidgets('lista la ruta y cambia el orden con los chips', (
      tester,
    ) async {
      await _montar(
        tester,
        const ExplorarScreen(),
        extra: [
          miViajeProvider.overrideWith((ref) async => _viaje),
          disponiblesEnMiRutaProvider.overrideWith(
            (ref) async => [
              _e(
                'a',
                EstadoEncomienda.disponible,
                destino: 'Lima',
                creada: DateTime(2026, 10, 1),
                vence: DateTime(2026, 11, 1),
              ),
              _e(
                'b',
                EstadoEncomienda.disponible,
                destino: 'Quito',
                creada: DateTime(2026, 10, 10),
                vence: DateTime(2026, 11, 20),
              ),
            ],
          ),
        ],
      );
      expect(find.text('2 encomiendas disponibles'), findsOneWidget);
      double y(String ciudad) => tester.getTopLeft(find.text(ciudad)).dy;
      // Más recientes primero: Quito (10 oct) antes que Lima (1 oct).
      expect(y('Quito'), lessThan(y('Lima')));
      await tester.tap(find.text('Vencen pronto'));
      await tester.pumpAndSettle();
      expect(y('Lima'), lessThan(y('Quito')));
    });

    testWidgets('sin viaje invita a registrarlo', (tester) async {
      await _montar(
        tester,
        const ExplorarScreen(),
        extra: [miViajeProvider.overrideWith((ref) async => null)],
      );
      expect(find.text('Primero registra tu viaje'), findsOneWidget);
      expect(find.text('Registrar viaje'), findsOneWidget);
    });
  });

  group('Registrar viaje', () {
    testWidgets('fecha en hoja iOS y nada sobre verificar el vuelo', (
      tester,
    ) async {
      await _montar(
        tester,
        const RegistrarViajeScreen(),
        extra: [viajeRepositoryProvider.overrideWithValue(_ViajesFalsos())],
      );
      // Verificar vuelo se quitó (docs/11 §2H): ningún texto lo menciona.
      expect(
        find.text('Los remitentes de tu ruta verán tu vuelo y fecha.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(RegExp('verific', caseSensitive: false)),
        findsNothing,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'AV24'),
        'av24',
      );
      expect(find.text('AV24'), findsWidgets); // mayúsculas al escribir
      await tester.tap(find.widgetWithText(TextFormField, 'Elige la fecha'));
      await tester.pumpAndSettle();
      expect(find.text('Fecha del vuelo'), findsWidgets);
      await tester.tap(find.text('Elegir esta fecha'));
      await tester.pumpAndSettle();
      expect(find.text('Verificar vuelo'), findsNothing);
    });

    testWidgets('una regla del backend se explica en una hoja', (tester) async {
      await _montar(
        tester,
        const RegistrarViajeScreen(),
        extra: [
          viajeRepositoryProvider.overrideWithValue(
            _ViajesFalsos(
              errorCrear: const ApiException(400, 'Ya tienes un viaje activo.'),
            ),
          ),
        ],
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'AV24'),
        'AV24',
      );
      await tester.tap(find.widgetWithText(TextFormField, 'Elige la fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir esta fecha'));
      await tester.pumpAndSettle();
      // Campos: vuelo (0), fecha (1), origen (2) y destino (3).
      for (final (indice, campo, ciudad) in [
        (2, 'Ciudad de origen', 'Bogota'),
        (3, 'Ciudad de destino', 'Miami'),
      ]) {
        await tester.ensureVisible(find.byType(TextFormField).at(indice));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextFormField).at(indice));
        await tester.pumpAndSettle();
        expect(find.text(campo), findsWidgets);
        await tester.tap(find.text(ciudad).last);
        await tester.pumpAndSettle();
      }
      await _tocar(tester, 'Registrar viaje');
      expect(find.text('No pudimos registrar el viaje'), findsOneWidget);
      expect(find.text('Ya tienes un viaje activo.'), findsOneWidget);
      expect(find.text('Ver mi viaje'), findsOneWidget);
    });
  });

  group('Encomienda del viajero', () {
    testWidgets('tomar muestra la responsabilidad y luego permite entregar', (
      tester,
    ) async {
      final repo = _EncomiendasFalsas();
      await _montar(
        tester,
        EncomiendaViajeroScreen(
          encomienda: _e('e1', EstadoEncomienda.disponible),
        ),
        extra: [encomiendaRepositoryProvider.overrideWithValue(repo)],
      );
      expect(find.text('USD 30'), findsOneWidget);
      await tester.tap(find.text('Tomar encomienda'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Eres responsable de lo que llevas'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sí, tomarla'));
      await tester.pumpAndSettle();
      expect(repo.tomada, 'e1');
      expect(find.textContaining('La encomienda es tuya'), findsOneWidget);

      // Ya es mía: la acción ahora es entregarla, escribiendo ENTREGAR.
      await tester.tap(find.text('Marcar como entregada'));
      await tester.pumpAndSettle();
      final confirmar = find.widgetWithText(Boton, 'Sí, ya la entregué');
      expect(tester.widget<Boton>(confirmar).onTap, isNull);
      await tester.enterText(find.byType(TextField).last, 'entregar');
      await tester.pump();
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(repo.nuevoEstado, EstadoEncomienda.entregada);
      expect(find.text('Calificar al remitente'), findsOneWidget);
    });

    testWidgets('el viajero puede escribir primero y ve al remitente', (
      tester,
    ) async {
      await _montar(
        tester,
        EncomiendaViajeroScreen(
          encomienda: _e('e1', EstadoEncomienda.tomada, viajero: 'yo'),
        ),
      );
      expect(find.textContaining('escriba primero'), findsNothing);
      // Queda claro que la lleva él y qué sigue, sin depender del toast.
      expect(find.text('Tú llevas esta encomienda'), findsOneWidget);
      expect(
        find.textContaining('1. Escríbele a Laura para recibir el paquete.'),
        findsOneWidget,
      );
      expect(find.text('La llevas tú'), findsOneWidget);
      final chat = find.widgetWithText(Boton, 'Escribir al remitente');
      expect(tester.widget<Boton>(chat).onTap, isNotNull);
      // Entregar es lo último: va como botón secundario.
      final entregar = find.widgetWithText(Boton, 'Marcar como entregada');
      expect(tester.widget<Boton>(entregar).variante, VarianteBoton.secundario);
      await tester.scrollUntilVisible(
        find.text('Laura'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Laura'), findsOneWidget);
    });

    testWidgets('el error de una acción va junto a ella', (tester) async {
      final repo = _EncomiendasFallan();
      await _montar(
        tester,
        EncomiendaViajeroScreen(
          encomienda: _e('e1', EstadoEncomienda.disponible),
        ),
        extra: [encomiendaRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.tap(find.text('Tomar encomienda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, tomarla'));
      await tester.pumpAndSettle();
      expect(find.text('Alguien la tomó antes que tú.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('desde un aviso, Entregar se explica en el pie', (
      tester,
    ) async {
      await _montar(
        tester,
        EncomiendaViajeroScreen(
          encomienda: _e('e1', EstadoEncomienda.tomada, viajero: 'yo'),
          accion: AccionPendiente.entregar,
        ),
      );
      expect(find.textContaining('Cuando la dejes en destino'), findsOneWidget);
      expect(find.text('Marcar como entregada'), findsOneWidget);
    });
  });
}

class _EncomiendasFallan extends _EncomiendasFalsas {
  @override
  Future<Encomienda?> tomar(String id) =>
      Future.error(const ApiException(409, 'Alguien la tomó antes que tú.'));
}
