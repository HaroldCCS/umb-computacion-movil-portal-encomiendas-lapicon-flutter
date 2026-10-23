import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/widgets/route_ticket.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/features/onboarding/elegir_rol_screen.dart';

/// Pruebas del sistema de diseño (sin Firebase ni red).
/// Se usan las fuentes por defecto para no descargar Google Fonts en tests.
Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? construirTema(Brightness.light, useGoogleFonts: false),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  // Los campos y botones v2 se prueban en test/widgets/componentes_test.dart.

  testWidgets('RouteTicket muestra la ruta y es accesible', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        const RouteTicket(
          origen: 'Bogota',
          destino: 'Miami',
          details: [TicketDetail(label: 'Fecha', value: '1 dic')],
        ),
      ),
    );
    expect(find.text('Bogota'), findsOneWidget);
    expect(find.text('Miami'), findsOneWidget);
    // Un solo nodo: la ruta una vez y luego los detalles.
    expect(
      tester.getSemantics(find.byType(RouteTicket)).label,
      'Ruta de Bogota a Miami\nFECHA\n1 dic',
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('TarjetaRol cumple contraste y área táctil '
        '(${dark ? 'oscuro' : 'claro'})', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              for (final rol in Rol.values)
                TarjetaRol(
                  rol: rol,
                  seleccionada: rol == Rol.viajero,
                  onTap: () {},
                ),
            ],
          ),
          theme: dark
              ? construirTema(Brightness.dark, useGoogleFonts: false)
              : construirTema(Brightness.light, useGoogleFonts: false),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
