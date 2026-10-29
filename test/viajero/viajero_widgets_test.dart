import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/features/viajero/widgets/viajero_widgets.dart';

const _encomienda = Encomienda(
  id: '1',
  ciudadOrigen: 'Bogota',
  ciudadDestino: 'Miami',
  observaciones: 'Libros',
  moneda: 'USD',
  valor: 25,
  estado: EstadoEncomienda.disponible,
  remitenteUid: 'rem',
);

Widget _wrap(Widget child) => MaterialApp(
  theme: construirTema(Brightness.light, useGoogleFonts: false),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('EncomiendaTicket destaca el valor y responde al toque', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _wrap(EncomiendaTicket(encomienda: _encomienda, onTap: () => taps++)),
    );
    expect(find.text('USD 25'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    await tester.tap(find.byType(EncomiendaTicket));
    expect(taps, 1);
    expect(find.bySemanticsLabel(RegExp('te pagan USD 25')), findsOneWidget);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('confirmarToma muestra el recordatorio y devuelve true', (
    tester,
  ) async {
    bool? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light, useGoogleFonts: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  resultado = await confirmarToma(context, _encomienda);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Eres responsable de lo que llevas'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.tap(find.text('Sí, tomarla'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
  });
}
