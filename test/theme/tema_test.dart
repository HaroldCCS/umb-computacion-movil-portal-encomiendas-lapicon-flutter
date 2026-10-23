import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/theme/vocabulario.dart';
import 'package:lapticon_app/core/widgets/monto.dart';
import 'package:lapticon_app/data/models/rol.dart';

/// Contraste WCAG entre dos colores opacos.
double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Colores', () {
    for (final (nombre, c) in [
      ('claro', Colores.claro),
      ('oscuro', Colores.oscuro),
    ]) {
      test('pares de texto cumplen AA (≥ 4.5:1) en $nombre', () {
        final pares = <String, (Color, Color)>{
          'texto/fondo': (c.texto, c.fondo),
          'texto/superficie': (c.texto, c.superficie),
          'texto2/fondo': (c.texto2, c.fondo),
          'texto2/superficie': (c.texto2, c.superficie),
          'texto2/superficie2': (c.texto2, c.superficie2),
          'marca/superficie': (c.marca, c.superficie),
          'sobreMarca/marcaSolido': (c.sobreMarca, c.marcaSolido),
          'marca/marcaSuave': (c.marca, c.marcaSuave),
          'sobreRemitente/remitente': (c.sobreRemitente, c.remitente),
          'sobreViajero/viajero': (c.sobreViajero, c.viajero),
          'exito/exitoSuave': (c.exito, c.exitoSuave),
          'atencion/atencionSuave': (c.atencion, c.atencionSuave),
          'peligro/peligroSuave': (c.peligro, c.peligroSuave),
          'info/infoSuave': (c.info, c.infoSuave),
          'exito/superficie': (c.exito, c.superficie),
          'atencion/superficie': (c.atencion, c.superficie),
          'peligro/superficie': (c.peligro, c.superficie),
        };
        for (final MapEntry(key: par, value: (frente, fondo))
            in pares.entries) {
          expect(
            _contraste(frente, fondo),
            greaterThanOrEqualTo(4.5),
            reason: '$par en $nombre',
          );
        }
      });
    }

    test('texto blanco sobre los degradados del hero', () {
      for (final g in [Degradados.remitente, Degradados.viajero]) {
        // El primer tono solo lleva texto grande (≥ 3:1); el resto, AA.
        expect(_contraste(Colors.white, g.colors.first), greaterThan(3));
        for (final color in g.colors.skip(1)) {
          expect(_contraste(Colors.white, color), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('sin sombras en modo oscuro', () {
      expect(Colores.claro.sombraTarjeta, isNotEmpty);
      expect(Colores.oscuro.sombraTarjeta, isEmpty);
    });

    test('lerp mezcla los colores y cambia conSombra a la mitad', () {
      final medio = Colores.claro.lerp(Colores.oscuro, 0.5);
      expect(
        medio.fondo,
        Color.lerp(Colores.claro.fondo, Colores.oscuro.fondo, 0.5),
      );
      expect(Colores.claro.lerp(Colores.oscuro, 0.4).conSombra, isTrue);
      expect(Colores.claro.lerp(Colores.oscuro, 0.6).conSombra, isFalse);
    });

    test('acento por rol', () {
      expect(Colores.claro.acento(Rol.remitente), Colores.claro.remitente);
      expect(Colores.claro.acento(Rol.viajero), Colores.claro.viajero);
      expect(Degradados.de(Rol.viajero), Degradados.viajero);
    });
  });

  group('construirTema', () {
    for (final brillo in Brightness.values) {
      test('expone los tokens y el esquema alineado ($brillo)', () {
        final tema = construirTema(brillo, useGoogleFonts: false);
        final c = tema.extension<Colores>()!;
        expect(tema.brightness, brillo);
        expect(c, brillo == Brightness.light ? Colores.claro : Colores.oscuro);
        expect(tema.scaffoldBackgroundColor, c.fondo);
        expect(tema.colorScheme.primary, c.marcaSolido);
        expect(tema.colorScheme.onSurface, c.texto);
        expect(tema.colorScheme.surfaceContainerLowest, c.superficie);
        expect(tema.textTheme.bodyLarge?.color, c.texto);
        expect(tema.textTheme.bodyMedium?.color, c.texto2);
        expect(tema.textTheme.labelSmall?.color, c.texto2);
        expect(tema.textTheme.displayLarge?.fontSize, 40);
        expect(
          tema.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<CupertinoPageTransitionsBuilder>(),
        );
      });
    }

    testWidgets('context.c lee los tokens del tema', (tester) async {
      late Colores leidos;
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(Brightness.dark, useGoogleFonts: false),
          home: Builder(
            builder: (context) {
              leidos = context.c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(leidos, Colores.oscuro);
    });
  });

  test('Vocabulario por rol', () {
    final remitente = Vocabulario.de(Rol.remitente);
    final viajero = Vocabulario.de(Rol.viajero);
    expect(remitente.crear, 'Nueva encomienda');
    expect(viajero.crear, 'Registrar viaje');
    expect(remitente.laContraparte, 'el viajero');
    expect(viajero.laContraparte, 'el remitente');
  });

  testWidgets('Monto formatea con moneda y cifras tabulares', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Monto(50000, moneda: 'cop', estilo: TextStyle(fontSize: 20)),
      ),
    );
    final texto = tester.widget<Text>(find.text('COP 50.000'));
    expect(texto.style?.fontFeatures, cifras);
    expect(texto.style?.fontSize, 20);
  });
}
