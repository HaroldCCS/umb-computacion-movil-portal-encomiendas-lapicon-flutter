import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/router/app_router.dart';
import 'package:lapticon_app/features/session/session_controller.dart';

void main() {
  test('sin sesión solo permite pantallas públicas', () {
    expect(redirectFor(SessionStatus.sinSesion, Routes.inicio), Routes.login);
    expect(redirectFor(SessionStatus.sinSesion, Routes.login), isNull);
    expect(redirectFor(SessionStatus.sinSesion, Routes.registro), isNull);
    expect(redirectFor(SessionStatus.sinSesion, Routes.recuperar), isNull);
  });

  test('cargando y error muestran el splash', () {
    expect(redirectFor(SessionStatus.cargando, Routes.login), Routes.splash);
    expect(redirectFor(SessionStatus.error, Routes.inicio), Routes.splash);
    expect(redirectFor(SessionStatus.cargando, Routes.splash), isNull);
  });

  test('onboarding obligatorio: perfil y luego rol', () {
    expect(
      redirectFor(SessionStatus.sinPerfil, Routes.inicio),
      Routes.completarPerfil,
    );
    expect(redirectFor(SessionStatus.sinRol, Routes.inicio), Routes.elegirRol);
    expect(redirectFor(SessionStatus.sinRol, Routes.elegirRol), isNull);
  });

  test('con todo listo no se vuelve al login ni al onboarding', () {
    expect(redirectFor(SessionStatus.listo, Routes.login), Routes.inicio);
    expect(
      redirectFor(SessionStatus.listo, Routes.completarPerfil),
      Routes.inicio,
    );
    expect(redirectFor(SessionStatus.listo, Routes.editarPerfil), isNull);
    expect(
      redirectFor(SessionStatus.listo, Routes.elegirRol),
      isNull,
      reason: 'permite cambiar de rol desde el perfil',
    );
  });
}
