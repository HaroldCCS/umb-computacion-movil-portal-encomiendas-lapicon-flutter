import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/toast.dart';
import 'package:lapticon_app/data/local/prefs.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/data/models/usuario.dart';
import 'package:lapticon_app/data/models/viaje.dart';
import 'package:lapticon_app/data/services/auth_service.dart';
import 'package:lapticon_app/features/auth/login_screen.dart';
import 'package:lapticon_app/features/auth/registro_screen.dart';
import 'package:lapticon_app/features/onboarding/elegir_rol_screen.dart';
import 'package:lapticon_app/features/perfil/perfil_screen.dart';
import 'package:lapticon_app/features/remitente/envios_screen.dart';
import 'package:lapticon_app/features/remitente/inicio_remitente_screen.dart';
import 'package:lapticon_app/features/remitente/nueva_encomienda_screen.dart';
import 'package:lapticon_app/features/remitente/remitente_providers.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/features/viajero/explorar_screen.dart';
import 'package:lapticon_app/features/viajero/mi_viaje_screen.dart';
import 'package:lapticon_app/features/viajero/viajero_local_store.dart';
import 'package:lapticon_app/features/viajero/viajero_providers.dart';
import 'package:lapticon_app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lista de verificación de docs/08 §8.6 sobre las pantallas principales:
/// contraste y áreas táctiles en claro y oscuro, y letra del sistema al
/// máximo (2×) en un teléfono de 360 dp sin desbordes.

class _Usuario implements User {
  @override
  String get uid => 'yo';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Sesion extends ChangeNotifier implements SessionController {
  @override
  User? get user => _Usuario();

  @override
  Usuario? get perfil => const Usuario(
    uid: 'yo',
    nombre: 'María Fernanda',
    apellido: 'Rodríguez Castellanos',
    telefono: '3001234567',
    nacionalidad: 'Colombia',
  );

  @override
  Rol? get rol => Rol.remitente;

  @override
  SessionStatus get status => SessionStatus.sinRol;

  @override
  String? get email => 'maria.fernanda@prueba.co';

  @override
  bool get rolEnServidor => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Auth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Encomienda _e(String id, EstadoEncomienda estado, String destino) => Encomienda(
  id: id,
  ciudadOrigen: 'San José del Guaviare',
  ciudadDestino: destino,
  observaciones: 'Dos libros y una chaqueta de invierno',
  moneda: 'COP',
  valor: 1250000,
  estado: estado,
  remitenteUid: 'r1',
  viajeroUid: 'v1',
  viajeroNombre: 'Andrés',
  remitenteNombre: 'Laura',
  creadaEn: DateTime(2026, 10, 1),
  fechaVencimiento: DateTime(2026, 11, 1),
);

final _envios = [
  _e('1', EstadoEncomienda.tomada, 'Ciudad de México'),
  _e('2', EstadoEncomienda.entregada, 'Buenos Aires'),
  _e('3', EstadoEncomienda.disponible, 'Miami'),
];

final _viaje = Viaje(
  id: 'v',
  numeroVuelo: 'AV1234',
  ciudadOrigen: 'San José del Guaviare',
  ciudadDestino: 'Ciudad de México',
  fechaViaje: DateTime(2026, 12, 1),
  estado: EstadoViaje.disponible,
);

/// (nombre, pantalla) de lo que se revisa.
final _pantallas = <(String, Widget)>[
  ('Login', const LoginScreen()),
  ('Registro', const RegistroScreen()),
  ('Elegir rol', const ElegirRolScreen()),
  ('Inicio remitente', const InicioRemitenteScreen()),
  ('Envíos', const EnviosScreen()),
  ('Nueva encomienda', const NuevaEncomiendaScreen()),
  ('Mi viaje', const MiViajeScreen()),
  ('Explorar', const ExplorarScreen()),
  ('Perfil', const PerfilScreen()),
];

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  required Brightness brillo,
  double escalaTexto = 1,
  Size tam = const Size(1080, 2400),
  double dpr = 2.6,
}) async {
  tester.view
    ..physicalSize = tam
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = Prefs(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(_Sesion()),
        authServiceProvider.overrideWithValue(_Auth()),
        prefsProvider.overrideWithValue(prefs),
        ciudadesProvider.overrideWith((ref) async => ['Bogota', 'Miami']),
        misEncomiendasProvider.overrideWith((ref) async => _envios),
        miViajeProvider.overrideWith((ref) async => _viaje),
        misEntregasProvider.overrideWith((ref) async => _envios),
        disponiblesEnMiRutaProvider.overrideWith((ref) async => _envios),
        historialViajesProvider.overrideWith((ref) async => [_viaje]),
        viajeroLocalStoreProvider.overrideWith(
          (ref) => ViajeroLocalStore.abrir(),
        ),
        resumenCalificacionesProvider.overrideWith(
          (ref, uid) async => const ResumenCalificaciones(
            total: 3,
            promedio: 4.7,
            calificaciones: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: construirTema(brillo, useGoogleFonts: false),
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
          child: Toasts(child: hijo!),
        ),
        home: pantalla,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (nombre, pantalla) in _pantallas) {
    for (final brillo in Brightness.values) {
      testWidgets('$nombre: contraste y área táctil (${brillo.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _montar(tester, pantalla, brillo: brillo);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('$nombre: letra 2× en 360 dp sin desbordes', (tester) async {
      // 360 × 740 dp (un Android pequeño) con la letra del sistema al doble.
      await _montar(
        tester,
        pantalla,
        brillo: Brightness.light,
        escalaTexto: 2,
        tam: const Size(360, 740),
        dpr: 1,
      );
      // Se recorre la pantalla para construir también lo que está abajo.
      final listas = find.byType(Scrollable);
      if (listas.evaluate().isNotEmpty) {
        await tester.drag(listas.first, const Offset(0, -2000));
        await tester.pumpAndSettle();
      }
      // (Si algo desborda, el framework de pruebas falla con el detalle.)
    });
  }
}
