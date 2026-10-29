import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/features/remitente/widgets/encomienda_ticket.dart';
import 'package:lapticon_app/features/remitente/widgets/status_timeline.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: construirTema(Brightness.light, useGoogleFonts: false),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('StatusTimeline marca el paso actual (accesible)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const StatusTimeline(estado: EstadoEncomienda.tomada)),
    );
    expect(find.text('Publicada'), findsOneWidget);
    expect(find.text('Calificada'), findsOneWidget);
    expect(find.bySemanticsLabel('Publicada: completado'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tomada por un viajero: paso actual'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Entregada: pendiente'), findsOneWidget);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('StatusTimeline muestra el estado terminal', (tester) async {
    await tester.pumpWidget(
      _wrap(const StatusTimeline(estado: EstadoEncomienda.vencida)),
    );
    expect(
      find.text('Ya no está publicada: venció o la retiraste.'),
      findsOneWidget,
    );
    expect(find.text('Publicada'), findsNothing);
  });

  testWidgets('EncomiendaTicket muestra ruta, valor y estado', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EncomiendaTicket(
          encomienda: Encomienda(
            id: '1',
            ciudadOrigen: 'Bogota',
            ciudadDestino: 'Miami',
            observaciones: 'libro',
            moneda: 'USD',
            valor: 10,
            estado: EstadoEncomienda.disponible,
            creadaEn: DateTime(2026, 12, 1),
          ),
        ),
      ),
    );
    expect(find.text('Bogota'), findsOneWidget);
    expect(find.text('Miami'), findsOneWidget);
    expect(find.text('USD 10'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });
}
