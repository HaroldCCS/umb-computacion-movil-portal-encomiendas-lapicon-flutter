import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/app_theme.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/features/calificaciones/rating_input.dart';
import 'package:lapticon_app/features/calificaciones/resenas_screen.dart';

void main() {
  test('etiquetas por puntaje', () {
    expect(etiquetaPuntaje(0), '');
    expect(etiquetaPuntaje(1), 'Malo');
    expect(etiquetaPuntaje(3), 'Bueno');
    expect(etiquetaPuntaje(5), 'Excelente');
  });

  test('sugerencias positivas y negativas', () {
    expect(sugerenciasPara(0), isEmpty);
    expect(sugerenciasPara(5), contains('Puntual'));
    expect(sugerenciasPara(2), contains('Llegó tarde'));
  });

  test('componerComentario une sugerencias y texto con límite', () {
    expect(componerComentario(['Puntual', 'Amable'], ''), 'Puntual. Amable');
    expect(
      componerComentario(['Puntual'], ' Todo bien '),
      'Puntual. Todo bien',
    );
    expect(componerComentario(const [], ''), '');
    expect(componerComentario(const [], 'x' * 400).length, 300);
  });

  test('distribucion cuenta por puntaje', () {
    final d = distribucion(const [
      Calificacion(calificacion: 5, comentario: ''),
      Calificacion(calificacion: 5, comentario: ''),
      Calificacion(calificacion: 2, comentario: ''),
      Calificacion(calificacion: 0, comentario: ''),
    ]);
    expect(d, [0, 0, 1, 0, 0, 2]);
  });

  testWidgets('RatingInput: tocar estrellas, etiqueta, semántica y área '
      'táctil', (tester) async {
    final handle = tester.ensureSemantics();
    var valor = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(useGoogleFonts: false),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => RatingInput(
                value: valor,
                onChanged: (v) => setState(() => valor = v),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Toca una estrella'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('4 de 5 estrellas'));
    await tester.pumpAndSettle();
    expect(valor, 4);
    expect(find.text('Muy bueno'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));

    await tester.tap(find.bySemanticsLabel('1 de 5 estrellas'));
    await tester.pumpAndSettle();
    expect(valor, 1);
    expect(find.text('Malo'), findsOneWidget);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
