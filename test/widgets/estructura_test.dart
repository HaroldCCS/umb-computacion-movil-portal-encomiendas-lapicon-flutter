import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/utils/formatters.dart';
import 'package:lapticon_app/core/widgets/barra_pestanas.dart';
import 'package:lapticon_app/core/widgets/boton.dart';
import 'package:lapticon_app/core/widgets/encabezado_app.dart';
import 'package:lapticon_app/core/widgets/monto.dart';
import 'package:lapticon_app/core/widgets/mosaico.dart';
import 'package:lapticon_app/core/widgets/pantalla.dart';
import 'package:lapticon_app/core/widgets/route_ticket.dart';
import 'package:lapticon_app/core/widgets/tarjeta_hero.dart';
import 'package:lapticon_app/data/models/rol.dart';

/// Pruebas de la estructura v2 (docs/08 §8.7, fase 3).
ThemeData _tema(Brightness b) => construirTema(b, useGoogleFonts: false);

Widget _app(Widget home, {Brightness brillo = Brightness.light}) =>
    MaterialApp(theme: _tema(brillo), home: home);

Widget _cuerpo(Widget child, {Brightness brillo = Brightness.light}) => _app(
  Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
  brillo: brillo,
);

const _items = [
  PestanaItem(Icons.home_outlined, 'Inicio'),
  PestanaItem(
    Icons.inventory_2_outlined,
    'Envíos',
    contador: 2,
    etiquetaContador: '2 por calificar',
  ),
  PestanaItem(Icons.chat_bubble_outline, 'Chats'),
  PestanaItem(Icons.person_outline, 'Perfil'),
];

Widget _hero(Rol rol) => TarjetaHero(
  rol: rol,
  titulo: 'Tus envíos activos',
  principal: const Text('3'),
  nota: 'Dos ya van en camino.',
  insignia: const EtiquetaVidrio('Vuelo verificado', icono: Icons.verified),
  avance: 0.4,
  etiquetaAvance: 'Entregadas',
  subTarjetas: const [
    SubTarjetaVidrio(
      etiqueta: 'En camino',
      icono: Icons.luggage,
      valor: Text('2'),
    ),
    SubTarjetaVidrio(
      etiqueta: 'Te pagan',
      icono: Icons.payments_outlined,
      valor: Monto(40, moneda: 'USD'),
    ),
  ],
);

void main() {
  test('fecha larga en español', () {
    expect(Fmt.fechaLarga(DateTime(2026, 10, 22)), 'Jueves, 22 de octubre');
    expect(Fmt.fechaLarga(DateTime(2026, 3, 1)), 'Domingo, 1 de marzo');
  });

  group('BarraPestanas', () {
    for (final brillo in Brightness.values) {
      testWidgets('cumple contraste y área táctil ($brillo)', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: BarraPestanas(
                items: _items,
                actual: 0,
                onCambio: (_) {},
                onMas: () {},
                etiquetaMas: 'Nueva encomienda',
              ),
            ),
            brillo: brillo,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('cambia de pestaña, anuncia el contador y crea', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var actual = 0;
      var creados = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: BarraPestanas(
                items: _items,
                actual: actual,
                onCambio: (i) => setState(() => actual = i),
                onMas: () => creados++,
                etiquetaMas: 'Nueva encomienda',
              ),
            ),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Envíos, 2 por calificar, pestaña 2 de 4'),
        findsOneWidget,
      );
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      expect(actual, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Chats'))),
        isSemantics(isSelected: true, isButton: true),
      );
      await tester.tap(find.byTooltip('Nueva encomienda'));
      expect(creados, 1);
      handle.dispose();
    });

    testWidgets('sin acción principal no muestra el "+"', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            bottomNavigationBar: BarraPestanas(
              items: _items,
              actual: 0,
              onCambio: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });
  });

  group('Pantalla', () {
    testWidgets('título grande, contenido y volver en rutas internas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Pantalla(
              titulo: 'Envíos',
              hijos: [
                Boton(
                  'Abrir detalle',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Pantalla(
                        titulo: 'Detalle',
                        textoAtras: 'Envíos',
                        hijos: [Text('Contenido del detalle')],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Envíos'), findsWidgets);
      // La pantalla raíz no tiene botón de volver.
      expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);

      await tester.tap(find.text('Abrir detalle'));
      await tester.pumpAndSettle();
      expect(find.text('Contenido del detalle'), findsOneWidget);
      expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);

      await tester.tap(find.byType(CupertinoNavigationBarBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Contenido del detalle'), findsNothing);
    });

    testWidgets('jalar para actualizar llama a alActualizar', (tester) async {
      var recargas = 0;
      await tester.pumpWidget(
        _app(
          Pantalla(
            titulo: 'Envíos',
            alActualizar: () async => recargas++,
            hijos: const [SizedBox(height: 200, child: Text('Lista'))],
          ),
        ),
      );
      await tester.drag(find.text('Lista'), const Offset(0, 500));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(recargas, 1);
    });

    testWidgets('en una pestaña deja espacio para la barra flotante', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Pantalla(
            titulo: 'Inicio',
            conBarraPestanas: true,
            hijos: [Text('Hola')],
          ),
        ),
      );
      final relleno = tester
          .widgetList<SliverPadding>(find.byType(SliverPadding))
          .map((p) => p.padding.resolve(TextDirection.ltr).bottom);
      expect(relleno, contains(Medidas.alturaTabbar + 24));
    });

    testWidgets('el pie queda fijo abajo', (tester) async {
      await tester.pumpWidget(
        _app(
          Pantalla(
            titulo: 'Detalle',
            hijos: const [Text('Contenido')],
            pie: Boton('Abrir chat', onTap: () {}),
          ),
        ),
      );
      final pie = tester.getRect(find.text('Abrir chat'));
      expect(pie.bottom, greaterThan(500));
    });
  });

  group('EncabezadoApp', () {
    test('saluda con el primer nombre', () {
      expect(EncabezadoApp.saludo('Laura Gómez'), 'Hola, Laura');
      expect(EncabezadoApp.saludo('  '), 'Hola');
    });

    testWidgets('fecha, avatar al perfil y área táctil', (tester) async {
      final handle = tester.ensureSemantics();
      var perfil = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: EncabezadoApp(
              usuario: 'Laura Gómez',
              rol: Rol.remitente,
              fecha: DateTime(2026, 10, 22),
              acciones: [
                BotonIcono(
                  icono: Icons.support_agent,
                  etiqueta: 'Asistente',
                  onTap: () {},
                ),
              ],
              alTocarAvatar: () => perfil++,
            ),
          ),
        ),
      );
      expect(find.text('Hola, Laura'), findsOneWidget);
      expect(find.text('Jueves, 22 de octubre'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Tu perfil'));
      expect(perfil, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  for (final brillo in Brightness.values) {
    for (final rol in Rol.values) {
      testWidgets('TarjetaHero legible ($rol, $brillo)', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_cuerpo(_hero(rol), brillo: brillo));
        await tester.pumpAndSettle();
        expect(find.text('USD 40'), findsOneWidget);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('Mosaicos y pase legibles y tocables ($brillo)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var toques = 0;
      await tester.pumpWidget(
        _cuerpo(
          Column(
            children: [
              GrillaMosaicos([
                Mosaico(
                  icono: Icons.star_outline,
                  color: Pastel.ambar,
                  etiqueta: 'Por calificar',
                  valor: const Text('2'),
                  onTap: () => toques++,
                ),
                const Mosaico(
                  icono: Icons.check_circle_outline,
                  color: Pastel.verde,
                  etiqueta: 'Entregadas',
                  valor: Text('5'),
                ),
              ]),
              const SizedBox(height: 16),
              RouteTicket(
                origen: 'Bogotá',
                destino: 'Miami',
                compact: true,
                onTap: () {},
                details: const [
                  TicketDetail(label: 'Te pagan', value: 'USD 20'),
                  TicketDetail(label: 'Vence', value: '22 nov'),
                ],
              ),
            ],
          ),
          brillo: brillo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Por calificar'));
      expect(toques, 1);
      // El mosaico se anuncia como un botón con su texto.
      expect(
        tester.getSemantics(find.text('Por calificar')),
        isSemantics(isButton: true, label: 'Por calificar\n2'),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('GrillaMosaicos aguanta un primer cuadro de ancho 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SizedBox(
            width: 0,
            child: GrillaMosaicos([
              Mosaico(
                icono: Icons.star_outline,
                color: Pastel.ambar,
                etiqueta: 'Por calificar',
                valor: Text('2'),
              ),
            ]),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la etiqueta del pase cabe en una línea ("TE PAGAN")', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cuerpo(
        const SizedBox(
          width: 90,
          child: TicketDetail(label: 'Te pagan', value: 'USD 20'),
        ),
      ),
    );
    final etiqueta = tester.widget<Text>(find.text('TE PAGAN'));
    expect(etiqueta.maxLines, 1);
    expect(tester.getSize(find.text('TE PAGAN')).height, lessThan(20));
  });
}
