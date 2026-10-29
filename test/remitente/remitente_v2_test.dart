import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapticon_app/core/router/routes.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/boton.dart';
import 'package:lapticon_app/core/widgets/toast.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/viaje.dart';
import 'package:lapticon_app/data/repositories/encomienda_repository.dart';
import 'package:lapticon_app/features/remitente/buscar_viajeros_screen.dart';
import 'package:lapticon_app/features/remitente/encomienda_detalle_screen.dart';
import 'package:lapticon_app/features/remitente/nueva_encomienda_screen.dart';
import 'package:lapticon_app/features/remitente/remitente_providers.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/providers.dart';

/// Pruebas de la fase 5b: nueva encomienda, detalle y buscar viajeros.

class _RepoFalso implements EncomiendaRepository {
  Map<String, Object>? creada;
  EstadoEncomienda? nuevoEstado;

  @override
  Future<Encomienda> crear({
    required String ciudadOrigen,
    required String ciudadDestino,
    required String observaciones,
    required String moneda,
    required num valor,
  }) async {
    creada = {
      'origen': ciudadOrigen,
      'destino': ciudadDestino,
      'observaciones': observaciones,
      'moneda': moneda,
      'valor': valor,
    };
    return _e(EstadoEncomienda.disponible);
  }

  @override
  Future<Encomienda?> cambiarEstado(String id, EstadoEncomienda estado) async {
    nuevoEstado = estado;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SesionFalsa extends ChangeNotifier implements SessionController {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Encomienda _e(EstadoEncomienda estado, {String? viajero}) => Encomienda(
  id: 'e1',
  ciudadOrigen: 'Bogota',
  ciudadDestino: 'Miami',
  observaciones: 'Dos libros',
  moneda: 'USD',
  valor: 25,
  estado: estado,
  viajeroUid: viajero,
  viajeroNombre: viajero == null ? null : 'Andrés',
  creadaEn: DateTime(2026, 10, 20),
);

/// Abre [pantalla] empujada desde una raíz, para probar `pop(resultado)`.
Future<List<Object?>> _montar(
  WidgetTester tester,
  Widget pantalla, {
  List extra = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final resultados = <Object?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: Boton(
              'abrir',
              onTap: () async => resultados.add(await context.push('/p')),
            ),
          ),
        ),
      ),
      GoRoute(path: '/p', builder: (_, _) => pantalla),
      GoRoute(
        path: Routes.calificar,
        builder: (_, _) => const Scaffold(body: Text('Calificar')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(_SesionFalsa()),
        ciudadesProvider.overrideWith((ref) async => ['Bogota', 'Miami']),
        resumenCalificacionesProvider.overrideWith(
          (ref, uid) async => const ResumenCalificaciones(
            total: 2,
            promedio: 4.5,
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
  return resultados;
}

/// Baja por la pantalla hasta [texto] y lo toca. (El formulario no es
/// perezoso: basta `ensureVisible`, con un pump antes del toque.)
Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

Future<void> _elegirCiudad(
  WidgetTester tester,
  String campo,
  String ciudad,
) async {
  await tester.tap(find.widgetWithText(TextFormField, campo).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(ciudad).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Nueva encomienda', () {
    testWidgets('no publica con campos vacíos y lo dice junto al botón', (
      tester,
    ) async {
      final repo = _RepoFalso();
      await _montar(
        tester,
        const NuevaEncomiendaScreen(),
        extra: [encomiendaRepositoryProvider.overrideWithValue(repo)],
      );
      await _tocar(tester, 'Publicar encomienda');
      expect(repo.creada, isNull);
      expect(find.text('Revisa los campos marcados en rojo.'), findsOneWidget);
    });

    testWidgets('publica con valor entero, moneda elegida y vuelve', (
      tester,
    ) async {
      final repo = _RepoFalso();
      final resultados = await _montar(
        tester,
        const NuevaEncomiendaScreen(),
        extra: [encomiendaRepositoryProvider.overrideWithValue(repo)],
      );
      await _elegirCiudad(tester, '¿Desde dónde envías?', 'Bogota');
      await _elegirCiudad(tester, '¿A dónde va?', 'Miami');
      await tester.enterText(find.widgetWithText(TextFormField, '0'), '25000');
      await tester.pump();
      expect(find.text('25.000'), findsOneWidget);
      await _tocar(tester, 'COP');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ej. Un libro y dos camisetas'),
        'Dos libros',
      );
      // La vista previa muestra lo que verán los viajeros.
      expect(find.text('COP 25.000'), findsOneWidget);

      await _tocar(tester, 'Publicar encomienda');
      expect(repo.creada, {
        'origen': 'Bogota',
        'destino': 'Miami',
        'observaciones': 'Dos libros',
        'moneda': 'COP',
        'valor': 25000,
      });
      expect(resultados, [true]);
      expect(find.text('Encomienda publicada'), findsOneWidget);
    });

    testWidgets('origen y destino iguales se avisan', (tester) async {
      await _montar(
        tester,
        const NuevaEncomiendaScreen(),
        extra: [encomiendaRepositoryProvider.overrideWithValue(_RepoFalso())],
      );
      await _elegirCiudad(tester, '¿Desde dónde envías?', 'Miami');
      await _elegirCiudad(tester, '¿A dónde va?', 'Miami');
      await _tocar(tester, 'Publicar encomienda');
      expect(
        find.text('El origen y el destino no pueden ser la misma ciudad.'),
        findsWidgets,
      );
    });
  });

  group('Detalle del remitente', () {
    testWidgets('retirar pide escribir RETIRAR y devuelve el cambio', (
      tester,
    ) async {
      final repo = _RepoFalso();
      final resultados = await _montar(
        tester,
        EncomiendaDetalleScreen(encomienda: _e(EstadoEncomienda.disponible)),
        extra: [encomiendaRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.tap(find.text('Retirar encomienda'));
      await tester.pumpAndSettle();
      Boton confirmar() =>
          tester.widget<Boton>(find.widgetWithText(Boton, 'Sí, retirarla'));
      expect(confirmar().onTap, isNull);
      await tester.enterText(find.byType(TextField), 'retirar');
      await tester.pump();
      await tester.tap(find.text('Sí, retirarla'));
      await tester.pumpAndSettle();

      expect(repo.nuevoEstado, EstadoEncomienda.vencida);
      expect(find.text('Encomienda retirada'), findsOneWidget);
      expect(find.text('Vencida'), findsOneWidget);
      // Ya no hay acción para una encomienda vencida.
      expect(find.text('Retirar encomienda'), findsNothing);

      // Volver avisa a la lista que hubo un cambio.
      final navegador = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navegador.maybePop();
      await tester.pumpAndSettle();
      expect(resultados, [true]);
    });

    testWidgets('tomada: quién la lleva va arriba y el estado lo explica', (
      tester,
    ) async {
      await _montar(
        tester,
        EncomiendaDetalleScreen(
          encomienda: _e(EstadoEncomienda.tomada, viajero: 'v1'),
        ),
      );
      expect(find.text('Tomada'), findsOneWidget);
      // Justo debajo del pase, antes que el estado (docs/11 §2G).
      final quien = tester.getTopLeft(find.text('QUIÉN LA LLEVA')).dy;
      final estado = tester.getTopLeft(find.text('ESTADO')).dy;
      expect(quien, lessThan(estado));
      expect(find.text('Escribirle'), findsOneWidget);
      expect(find.text('Quién la llevó'.toUpperCase()), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Andrés aceptó llevarla. Coordinen por chat dónde y cuándo se la '
          'entregas.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('desde un aviso, Calificar se explica en el pie', (
      tester,
    ) async {
      await _montar(
        tester,
        EncomiendaDetalleScreen(
          encomienda: _e(EstadoEncomienda.entregada, viajero: 'v1'),
          accion: AccionPendiente.calificar,
        ),
      );
      expect(
        find.text('Califica a Andrés: tu opinión ayuda a otros remitentes.'),
        findsOneWidget,
      );
      expect(find.text('Calificar al viajero'), findsOneWidget);
      expect(find.text('Ver chat'), findsOneWidget);
      // "Quién la lleva" está al final de la lista (perezosa).
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('★ 4,5 (2 reseñas)'), findsOneWidget);
    });
  });

  group('Buscar viajeros', () {
    final viaje = Viaje(
      id: 'v',
      numeroVuelo: 'AV10',
      ciudadOrigen: 'Bogota',
      ciudadDestino: 'Miami',
      fechaViaje: DateTime(2026, 12, 1),
      estado: EstadoViaje.disponible,
      viajeroUid: 'v1',
      viajeroNombre: 'Andrés Ruiz',
    );

    testWidgets('busca por ruta completa y muestra el nombre (docs/11 §2C)', (
      tester,
    ) async {
      final pedidas = <({String origen, String destino})>[];
      await _montar(
        tester,
        const BuscarViajerosScreen(),
        extra: [
          viajerosEnRutaProvider.overrideWith((ref, ruta) async {
            pedidas.add(ruta);
            return [viaje];
          }),
        ],
      );
      expect(find.text('Encuentra quién viaja'), findsOneWidget);
      // Solo con el origen todavía no busca: hace falta la ruta completa.
      await _elegirCiudad(tester, 'Elige la ciudad de origen', 'Bogota');
      expect(find.text('Encuentra quién viaja'), findsOneWidget);
      await _elegirCiudad(tester, 'Elige la ciudad de destino', 'Miami');
      expect(find.text('Andrés Ruiz'), findsOneWidget);
      expect(pedidas, [(origen: 'Bogota', destino: 'Miami')]);
      // Intercambiar busca la ruta inversa.
      await tester.tap(find.bySemanticsLabel('Intercambiar origen y destino'));
      await tester.pumpAndSettle();
      expect(pedidas.last, (origen: 'Miami', destino: 'Bogota'));
    });

    testWidgets('sin viajeros invita a publicar igual', (tester) async {
      await _montar(
        tester,
        const BuscarViajerosScreen(),
        extra: [
          viajerosEnRutaProvider.overrideWith((ref, ruta) async => const []),
        ],
      );
      await _elegirCiudad(tester, 'Elige la ciudad de origen', 'Miami');
      await _elegirCiudad(tester, 'Elige la ciudad de destino', 'Bogota');
      expect(find.text('Nadie viaja Miami → Bogota por ahora'), findsOneWidget);
      expect(find.text('Publicar encomienda'), findsOneWidget);
    });
  });
}
