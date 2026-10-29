import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/theme/tema.dart';
import 'package:lapticon_app/core/utils/validators.dart';
import 'package:lapticon_app/core/widgets/aviso.dart';
import 'package:lapticon_app/core/widgets/avatar.dart';
import 'package:lapticon_app/core/widgets/boton.dart';
import 'package:lapticon_app/core/widgets/campo.dart';
import 'package:lapticon_app/core/widgets/chips.dart';
import 'package:lapticon_app/core/widgets/entrada.dart';
import 'package:lapticon_app/core/widgets/esqueleto.dart';
import 'package:lapticon_app/core/widgets/grupo.dart';
import 'package:lapticon_app/core/widgets/hoja.dart';
import 'package:lapticon_app/core/widgets/icono_en_caja.dart';
import 'package:lapticon_app/core/widgets/insignia.dart';
import 'package:lapticon_app/core/widgets/presionable.dart';
import 'package:lapticon_app/core/widgets/progreso.dart';
import 'package:lapticon_app/core/widgets/tarjeta.dart';
import 'package:lapticon_app/core/widgets/toast.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/rol.dart';

/// Pruebas de los componentes base del sistema v2 (docs/08 §8.3).
Widget _app(
  Widget child, {
  Brightness brillo = Brightness.light,
  bool sinAnimaciones = false,
}) => MaterialApp(
  theme: construirTema(brillo, useGoogleFonts: false),
  builder: (context, hijo) => Toasts(
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: sinAnimaciones),
      child: hijo!,
    ),
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

/// Todos los componentes estáticos juntos, para revisar contraste y toque.
Widget _galeria() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const Tarjeta(child: Text('Contenido de tarjeta')),
    const SizedBox(height: 12),
    Tarjeta(etiqueta: 'Abrir', onTap: () {}, child: const Text('Tocable')),
    const SizedBox(height: 12),
    Grupo(
      titulo: 'Mis datos',
      pie: 'Así te reconocerán.',
      hijos: [
        const Fila('Nombre', Text('Laura'), extra: 'Visible para todos'),
        FilaAccion(
          titulo: 'Editar perfil',
          subtitulo: 'Nombre y teléfono',
          icono: Icons.edit_outlined,
          onTap: () {},
        ),
        FilaAccion(titulo: 'Cerrar sesión', destructiva: true, onTap: () {}),
      ],
    ),
    const SizedBox(height: 12),
    for (final v in VarianteBoton.values) ...[
      Boton('Botón ${v.name}', variante: v, onTap: () {}),
      const SizedBox(height: 8),
    ],
    Row(
      children: [
        Boton('Chico', chico: true, ancho: false, onTap: () {}),
        const SizedBox(width: 8),
        const Boton('Inactivo', ancho: false, onTap: null),
      ],
    ),
    const SizedBox(height: 12),
    Campo(
      etiqueta: 'Correo',
      controlador: TextEditingController(text: 'laura@mail.com'),
      ayuda: 'Te enviaremos avisos aquí.',
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in EstadoEncomienda.values) Insignia.encomienda(e),
        for (final e in EstadoViaje.values) Insignia.viaje(e),
        const Insignia('Atención', tipo: TipoInsignia.peligro),
      ],
    ),
    const SizedBox(height: 12),
    const Row(
      children: [
        IconoEnCaja(Icons.luggage, color: Pastel.ambar),
        SizedBox(width: 8),
        Avatar('Laura Gómez'),
        SizedBox(width: 8),
        Expanded(child: Progreso(0.6)),
      ],
    ),
    const SizedBox(height: 12),
    Chips<int>(
      opciones: const [(0, 'Activas', 2), (1, 'Entregadas', null)],
      valor: 0,
      onCambio: (_) {},
    ),
    const SizedBox(height: 12),
    for (final t in TipoAviso.values) ...[
      Aviso('Mensaje de ${t.name}.', titulo: 'Título', tipo: t),
      const SizedBox(height: 8),
    ],
    Vacio(
      titulo: 'Aún no has enviado nada',
      icono: Icons.inventory_2_outlined,
      texto: 'Publica tu primera encomienda.',
      accion: Boton('Publicar', onTap: () {}),
    ),
    const SizedBox(height: 12),
    ErrorCarga(mensaje: 'Revisa tu conexión.', alReintentar: () {}),
  ],
);

void main() {
  for (final brillo in Brightness.values) {
    testWidgets('galería cumple contraste y área táctil ($brillo)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 3600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_galeria(), brillo: brillo));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  group('Boton', () {
    testWidgets('responde al toque y lo expone al lector', (tester) async {
      final handle = tester.ensureSemantics();
      var toques = 0;
      await tester.pumpWidget(_app(Boton('Publicar', onTap: () => toques++)));
      expect(
        tester.getSemantics(find.byType(Boton)),
        isSemantics(
          label: 'Publicar',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(Boton));
      expect(toques, 1);
      handle.dispose();
    });

    testWidgets('mientras carga muestra el texto de carga y no responde', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        _app(
          Boton(
            'Publicar',
            textoCargando: 'Publicando…',
            cargando: true,
            onTap: () => toques++,
          ),
        ),
      );
      expect(find.text('Publicando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(Boton));
      expect(toques, 0);
      // Sigue viéndose activo (no atenuado) mientras carga.
      final opacidad = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(Presionable),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacidad.opacity, 1);
    });
  });

  testWidgets('Presionable sin acción se atenúa', (tester) async {
    await tester.pumpWidget(_app(const Presionable(child: Text('Inactivo'))));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.4,
    );
  });

  group('Campo', () {
    testWidgets('valida al salir, limpia el error al corregir y marca válido', (
      tester,
    ) async {
      final correo = TextEditingController();
      final otro = TextEditingController();
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Campo(
                etiqueta: 'Correo',
                controlador: correo,
                validador: Validators.email,
              ),
              Campo(etiqueta: 'Otro', controlador: otro),
            ],
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'laura@');
      await tester.pump();
      expect(find.text('Revisa el correo: parece incompleto.'), findsNothing);

      await tester.tap(find.byType(TextFormField).last);
      await tester.pump();
      expect(find.text('Revisa el correo: parece incompleto.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'laura@mail.com',
      );
      await tester.pump();
      expect(find.text('Revisa el correo: parece incompleto.'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('CampoContrasena avisa el mínimo y permite ver el texto', (
      tester,
    ) async {
      final clave = TextEditingController();
      await tester.pumpWidget(
        _app(CampoContrasena(controlador: clave, minimo: 6, nueva: true)),
      );
      expect(find.text('Mínimo 6 caracteres.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'secreta1');
      await tester.pump();
      expect(find.text('✓ Mínimo 6 caracteres.'), findsOneWidget);

      TextField campo() => tester.widget<TextField>(find.byType(TextField));
      expect(campo().obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(campo().obscureText, isFalse);
    });

    testWidgets('CampoMonto agrupa miles y devuelve el número', (tester) async {
      final monto = TextEditingController();
      await tester.pumpWidget(
        _app(CampoMonto(controlador: monto, moneda: 'cop')),
      );
      await tester.enterText(find.byType(TextFormField), '1234567');
      await tester.pump();
      expect(monto.text, '1.234.567');
      expect(CampoMonto.valorDe(monto), 1234567);
      expect(find.text('COP'), findsOneWidget);
      expect(CampoMonto.valorDe(TextEditingController()), 0);
    });
  });

  testWidgets('Chips cambian la selección y la anuncian', (tester) async {
    final handle = tester.ensureSemantics();
    var valor = 'activas';
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Chips<String>(
            opciones: const [
              ('activas', 'Activas', 3),
              ('entregadas', 'Entregadas', 0),
            ],
            valor: valor,
            onCambio: (v) => setState(() => valor = v),
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsNothing); // el contador en 0 no se muestra
    await tester.tap(find.text('Entregadas'));
    await tester.pump();
    expect(valor, 'entregadas');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Entregadas')),
      isSemantics(isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('Insignia de encomienda: ícono + texto + etiqueta accesible', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(Insignia.encomienda(EstadoEncomienda.tomada)));
    // El remitente ve "Tomada" con una persona (docs/11 §2G).
    expect(find.text('Tomada'), findsOneWidget);
    expect(find.byIcon(Icons.how_to_reg_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Estado: Tomada'), findsOneWidget);
    // El viajero que la lleva: "La llevas tú" con la maleta.
    await tester.pumpWidget(
      _app(Insignia.encomienda(EstadoEncomienda.tomada, rol: Rol.viajero)),
    );
    expect(find.text('La llevas tú'), findsOneWidget);
    expect(find.byIcon(Icons.luggage), findsOneWidget);
    expect(EstadoEncomienda.entregada.etiquetaPara(Rol.viajero), 'Entregada');
    handle.dispose();
  });

  testWidgets('Grupo ocupa todo el ancho aunque el contenido sea corto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Grupo(titulo: 'Corto', hijos: [Text('USD 10')])),
    );
    // Ancho disponible: la ventana menos el relleno de 16 a cada lado.
    final disponible = tester.getSize(find.byType(Scaffold)).width - 32;
    final tarjeta = tester.getSize(
      find
          .ancestor(of: find.text('USD 10'), matching: find.byType(Container))
          .first,
    );
    expect(tarjeta.width, disponible);
    // Y el contenido corto queda a la izquierda, no centrado.
    expect(
      tester.getTopLeft(find.text('USD 10')).dx,
      tester.getTopLeft(find.byType(Grupo)).dx,
    );
  });

  testWidgets('Fila: etiqueta a la izquierda y valor pegado a la derecha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Grupo(hijos: [Fila('Teléfono', Text('3001234567'))])),
    );
    final fila = tester.getRect(find.byType(Fila));
    // 16 de relleno a cada lado.
    expect(tester.getTopLeft(find.text('Teléfono')).dx, fila.left + 16);
    expect(tester.getTopRight(find.text('3001234567')).dx, fila.right - 16);
  });

  test('Avatar: iniciales y tono estable', () {
    expect(Avatar.iniciales('Laura Gómez'), 'LG');
    expect(Avatar.iniciales('  andrés  '), 'A');
    expect(Avatar.iniciales(''), '?');
    expect(Avatar.tono('Laura'), Avatar.tono('laura '));
  });

  group('Toasts', () {
    testWidgets('aparecen y se van solos', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Boton(
              'Guardar',
              onTap: () => mostrarToast(context, 'Perfil actualizado'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Boton));
      await tester.pump();
      expect(find.text('Perfil actualizado'), findsOneWidget);
      await tester.pump(Toasts.duracion);
      await tester.pump();
      expect(find.text('Perfil actualizado'), findsNothing);
    });

    testWidgets('sin capa de toasts usan un SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(Brightness.light, useGoogleFonts: false),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => mostrarToast(context, 'Listo'),
                child: const Text('ok'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ok'));
      await tester.pump();
      expect(find.widgetWithText(SnackBar, 'Listo'), findsOneWidget);
    });
  });

  group('Hojas', () {
    Future<bool?> abrir(WidgetTester tester, {String? palabra}) async {
      bool? resultado;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Boton(
              'Retirar',
              onTap: () async => resultado = await confirmarConHoja(
                context,
                titulo: '¿Retirar la encomienda?',
                mensaje: 'Dejará de estar publicada.',
                confirmarTexto: 'Sí, retirarla',
                destructivo: true,
                palabra: palabra,
              ),
            ),
          ),
          sinAnimaciones: true,
        ),
      );
      await tester.tap(find.text('Retirar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Retirar la encomienda?'), findsOneWidget);
      return resultado;
    }

    testWidgets('con palabra, el botón se habilita al escribirla', (
      tester,
    ) async {
      await abrir(tester, palabra: 'RETIRAR');
      Boton confirmar() =>
          tester.widget<Boton>(find.widgetWithText(Boton, 'Sí, retirarla'));
      expect(confirmar().onTap, isNull);
      await tester.enterText(find.byType(TextField), 'retirar');
      await tester.pump();
      expect(confirmar().onTap, isNotNull);
      await tester.tap(find.text('Sí, retirarla'));
      await tester.pumpAndSettle();
      expect(find.text('¿Retirar la encomienda?'), findsNothing);
    });

    testWidgets('cancelar y cerrar devuelven false', (tester) async {
      bool? resultado;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Boton(
              'Abrir',
              onTap: () async => resultado = await confirmarConHoja(
                context,
                titulo: 'Título',
                mensaje: 'Mensaje',
                confirmarTexto: 'Sí',
              ),
            ),
          ),
          sinAnimaciones: true,
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No, volver'));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Cerrar'));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);
    });
  });

  group('Reducir movimiento', () {
    testWidgets('Entrada no anima', (tester) async {
      await tester.pumpWidget(
        _app(
          const Entrada(indice: 3, child: Text('Hola')),
          sinAnimaciones: true,
        ),
      );
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Hola'), findsOneWidget);
    });

    testWidgets('Entrada anima y termina visible', (tester) async {
      await tester.pumpWidget(_app(const Entrada(child: Text('Hola'))));
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    testWidgets('Esqueleto queda quieto', (tester) async {
      await tester.pumpWidget(
        _app(const EsqueletoLista(primero: 160), sinAnimaciones: true),
      );
      // Si siguiera animando, pumpAndSettle no terminaría nunca.
      await tester.pumpAndSettle();
      expect(find.byType(Esqueleto), findsNWidgets(4));
    });
  });
}
