import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/app_theme.dart';
import 'package:lapticon_app/core/utils/validators.dart';
import 'package:lapticon_app/core/widgets/app_text_field.dart';
import 'package:lapticon_app/core/widgets/primary_button.dart';
import 'package:lapticon_app/core/widgets/route_ticket.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/features/onboarding/elegir_rol_screen.dart';

/// Pruebas del sistema de diseño (sin Firebase ni red).
/// Se usan las fuentes por defecto para no descargar Google Fonts en tests.
Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(useGoogleFonts: false),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('AppTextField valida al salir del campo y limpia el error al '
      'corregir', (tester) async {
    final email = TextEditingController();
    final otro = TextEditingController();
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            AppTextField(
              label: 'Correo',
              controller: email,
              validator: Validators.email,
            ),
            AppTextField(label: 'Otro', controller: otro),
          ],
        ),
      ),
    );

    // Mientras escribe por primera vez no se muestra error.
    await tester.enterText(find.byType(TextFormField).first, 'laura@');
    await tester.pump();
    expect(find.text('Revisa el correo: parece incompleto.'), findsNothing);

    // Al salir del campo, sí.
    await tester.tap(find.byType(TextFormField).last);
    await tester.pump();
    expect(find.text('Revisa el correo: parece incompleto.'), findsOneWidget);

    // Al corregir, el error desaparece en la misma pulsación.
    await tester.enterText(find.byType(TextFormField).first, 'laura@mail.com');
    await tester.pump();
    expect(find.text('Revisa el correo: parece incompleto.'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('PrimaryButton deshabilitado mientras carga', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        PrimaryButton(label: 'Entrar', loading: true, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

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
    testWidgets('RoleCard cumple contraste y área táctil '
        '(${dark ? 'oscuro' : 'claro'})', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              for (final rol in Rol.values)
                RoleCard(rol: rol, selected: rol == Rol.viajero, onTap: () {}),
            ],
          ),
          theme: dark
              ? AppTheme.dark(useGoogleFonts: false)
              : AppTheme.light(useGoogleFonts: false),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
