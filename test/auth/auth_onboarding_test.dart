import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/network/app_exception.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/toast.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/data/services/auth_service.dart';
import 'package:lapticon_app/features/auth/login_screen.dart';
import 'package:lapticon_app/features/auth/recuperar_screen.dart';
import 'package:lapticon_app/features/auth/registro_screen.dart';
import 'package:lapticon_app/features/onboarding/elegir_rol_screen.dart';
import 'package:lapticon_app/features/perfil/widgets/pais_picker.dart';
import 'package:lapticon_app/features/session/session_controller.dart';
import 'package:lapticon_app/features/splash/splash_screen.dart';
import 'package:lapticon_app/providers.dart';

/// Pruebas de la fase 5a: autenticación y onboarding con el sistema v2.

/// Firebase falso: cada operación falla con [error] (o funciona si es null).
class _AuthFalsa implements AuthService {
  _AuthFalsa([this.error]);

  final AuthException? error;
  int llamadas = 0;

  Future<void> _responder() async {
    llamadas++;
    if (error != null) throw error!;
  }

  @override
  Future<void> iniciarSesion(String email, String password) => _responder();

  @override
  Future<void> crearCuenta(String email, String password) => _responder();

  @override
  Future<void> recuperarPassword(String email) => _responder();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SesionFalsa extends ChangeNotifier implements SessionController {
  _SesionFalsa({this.status = SessionStatus.sinRol, this.error});

  @override
  final SessionStatus status;

  @override
  final String? error;

  Rol? elegido;

  @override
  Future<void> elegirRol(Rol rol) async {
    elegido = rol;
    throw const NetworkException('No pudimos guardar tu rol.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  AuthService? auth,
  SessionController? sesion,
  List extra = const [],
  Brightness brillo = Brightness.light,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        if (sesion != null) sessionProvider.overrideWithValue(sesion),
        ...extra.cast(),
      ],
      child: MaterialApp(
        theme: construirTema(brillo, useGoogleFonts: false),
        builder: (context, hijo) => Toasts(child: hijo!),
        home: pantalla,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Login', () {
    testWidgets('el error de Firebase aparece junto al botón', (tester) async {
      final auth = _AuthFalsa(
        const AuthException(
          'Correo o contraseña incorrectos.',
          code: 'invalid-credential',
        ),
      );
      await _montar(tester, const LoginScreen(), auth: auth);
      await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
      await tester.enterText(find.byType(TextFormField).last, 'secreta1');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(auth.llamadas, 1);
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('no llama a Firebase si el formulario es inválido', (
      tester,
    ) async {
      final auth = _AuthFalsa();
      await _montar(tester, const LoginScreen(), auth: auth);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(auth.llamadas, 0);
    });

    for (final brillo in Brightness.values) {
      testWidgets('cumple contraste y área táctil ($brillo)', (tester) async {
        final handle = tester.ensureSemantics();
        await _montar(
          tester,
          const LoginScreen(),
          auth: _AuthFalsa(),
          brillo: brillo,
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  testWidgets('Registro: fuerza, mínimo y error en línea', (tester) async {
    final auth = _AuthFalsa(
      const AuthException(
        'Ya existe una cuenta con ese correo.',
        code: 'email-already-in-use',
      ),
    );
    await _montar(tester, const RegistroScreen(), auth: auth);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'laura@mail.com');
    await tester.enterText(campos.at(1), 'Clave2026!');
    await tester.pump();
    expect(find.text('✓ Mínimo 6 caracteres.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Seguridad de la contraseña')),
      findsOneWidget,
    );
    await tester.enterText(campos.at(2), 'Clave2026!');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();
    expect(auth.llamadas, 1);
    expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
  });

  testWidgets('Recuperar no revela si el correo existe', (tester) async {
    final auth = _AuthFalsa(
      const AuthException('No existe.', code: 'user-not-found'),
    );
    await _montar(tester, const RecuperarScreen(), auth: auth);
    await tester.enterText(find.byType(TextFormField), 'nadie@mail.com');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('Enlace enviado'), findsOneWidget);
    expect(
      find.textContaining('Si nadie@mail.com está registrado'),
      findsOneWidget,
    );
    expect(find.text('No existe.'), findsNothing);
  });

  group('Elegir rol', () {
    testWidgets('Continuar se habilita al elegir y el error va en línea', (
      tester,
    ) async {
      final sesion = _SesionFalsa();
      await _montar(tester, const ElegirRolScreen(), sesion: sesion);
      expect(find.text('PASO 2 DE 2'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(sesion.elegido, isNull);

      await tester.tap(find.text(Rol.viajero.titulo));
      await tester.pump();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(sesion.elegido, Rol.viajero);
      expect(find.text('No pudimos guardar tu rol.'), findsOneWidget);
    });

    testWidgets('la tarjeta elegida se anuncia como seleccionada', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _montar(tester, const ElegirRolScreen(), sesion: _SesionFalsa());
      await tester.tap(find.text(Rol.remitente.titulo));
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(TarjetaRol).first),
        isSemantics(
          isSelected: true,
          isButton: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('Splash con error ofrece reintentar y cerrar sesión', (
    tester,
  ) async {
    await _montar(
      tester,
      const SplashScreen(),
      sesion: _SesionFalsa(
        status: SessionStatus.error,
        error: 'Sin conexión a internet.',
      ),
    );
    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('Selector de país: busca, permite texto libre y devuelve', (
    tester,
  ) async {
    String? elegido;
    await _montar(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                elegido = await showPaisPicker(context, actual: 'Colombia'),
            child: const Text('abrir'),
          ),
        ),
      ),
      extra: [
        paisesProvider.overrideWith(
          (ref) async => ['Colombia', 'Spain', 'Peru', 'Chile'],
        ),
      ],
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Nacionalidad'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget); // Colombia

    await tester.enterText(find.byType(TextField), 'sp');
    await tester.pump();
    expect(find.text('Spain'), findsOneWidget);
    expect(find.text('Peru'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Atlantis');
    await tester.pump();
    await tester.tap(find.text('Usar "Atlantis"'));
    await tester.pumpAndSettle();
    expect(elegido, 'Atlantis');
  });
}
