import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/rol.dart';

/// Tokens de color de Lapticon v2 (docs/08 §8.2). Se leen con `context.c.xxx`;
/// ningún widget usa un color directo, así nada queda blanco en modo oscuro.
@immutable
class Colores extends ThemeExtension<Colores> {
  const Colores({
    required this.fondo,
    required this.superficie,
    required this.superficie2,
    required this.separador,
    required this.texto,
    required this.texto2,
    required this.texto3,
    required this.marca,
    required this.marcaSolido,
    required this.sobreMarca,
    required this.marcaSuave,
    required this.remitente,
    required this.sobreRemitente,
    required this.viajero,
    required this.sobreViajero,
    required this.exito,
    required this.exitoSuave,
    required this.atencion,
    required this.atencionSuave,
    required this.peligro,
    required this.peligroSuave,
    required this.info,
    required this.infoSuave,
    required this.conSombra,
  });

  final Color fondo, superficie, superficie2, separador;
  final Color texto, texto2, texto3;

  /// Cielo para enlaces e íconos activos; Medianoche para el botón primario.
  final Color marca, marcaSolido, sobreMarca, marcaSuave;

  /// Acento de cada rol: ámbar (paquete) y cielo (avión).
  final Color remitente, sobreRemitente, viajero, sobreViajero;

  final Color exito, exitoSuave, atencion, atencionSuave;
  final Color peligro, peligroSuave, info, infoSuave;

  /// En oscuro no hay sombras: un resplandor sobre negro se ve como mancha.
  final bool conSombra;

  static const claro = Colores(
    fondo: Color(0xFFF5F6F8),
    superficie: Color(0xFFFFFFFF),
    superficie2: Color(0xFFEFF1F5),
    separador: Color(0xFFE2E6EC),
    texto: Color(0xFF111A2C),
    texto2: Color(0xFF5C6678),
    texto3: Color(0xFF8E97A6),
    marca: Color(0xFF0B63C4),
    marcaSolido: Color(0xFF1B2A4A),
    sobreMarca: Color(0xFFFFFFFF),
    marcaSuave: Color(0xFFE4EDFA),
    remitente: Color(0xFFF2A93B),
    sobreRemitente: Color(0xFF1B2A4A),
    viajero: Color(0xFF0B63C4),
    sobreViajero: Color(0xFFFFFFFF),
    exito: Color(0xFF17663F),
    exitoSuave: Color(0xFFDEF5E9),
    atencion: Color(0xFF8A4B00),
    atencionSuave: Color(0xFFFEF2DC),
    peligro: Color(0xFFC62828),
    peligroSuave: Color(0xFFFDE6E6),
    info: Color(0xFF0D47A1),
    infoSuave: Color(0xFFE3ECFA),
    conSombra: true,
  );

  static const oscuro = Colores(
    fondo: Color(0xFF000000),
    superficie: Color(0xFF171A20),
    superficie2: Color(0xFF252A33),
    separador: Color(0xFF323844),
    texto: Color(0xFFF3F5F8),
    texto2: Color(0xFFA6AEBB),
    texto3: Color(0xFF717A88),
    marca: Color(0xFF8CC4FF),
    marcaSolido: Color(0xFFAFC6FF),
    sobreMarca: Color(0xFF0E1A33),
    marcaSuave: Color(0xFF14284A),
    remitente: Color(0xFFFFC56E),
    sobreRemitente: Color(0xFF11141B),
    viajero: Color(0xFF8CC4FF),
    sobreViajero: Color(0xFF00213F),
    exito: Color(0xFF5CD696),
    exitoSuave: Color(0xFF0E3624),
    atencion: Color(0xFFFABE46),
    atencionSuave: Color(0xFF3E2A08),
    peligro: Color(0xFFF87878),
    peligroSuave: Color(0xFF461616),
    info: Color(0xFF8CC4FF),
    infoSuave: Color(0xFF14284A),
    conSombra: false,
  );

  /// Acento del [rol] y el color del texto/ícono encima de él.
  Color acento(Rol rol) => rol == Rol.remitente ? remitente : viajero;
  Color sobreAcento(Rol rol) =>
      rol == Rol.remitente ? sobreRemitente : sobreViajero;

  List<BoxShadow> get sombraTarjeta => conSombra
      ? const [
          BoxShadow(
            color: Color(0x0A101820),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0D101820),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ]
      : const [];

  @override
  Colores copyWith() => this;

  @override
  Colores lerp(ThemeExtension<Colores>? otro, double t) {
    if (otro is! Colores) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Colores(
      fondo: l(fondo, otro.fondo),
      superficie: l(superficie, otro.superficie),
      superficie2: l(superficie2, otro.superficie2),
      separador: l(separador, otro.separador),
      texto: l(texto, otro.texto),
      texto2: l(texto2, otro.texto2),
      texto3: l(texto3, otro.texto3),
      marca: l(marca, otro.marca),
      marcaSolido: l(marcaSolido, otro.marcaSolido),
      sobreMarca: l(sobreMarca, otro.sobreMarca),
      marcaSuave: l(marcaSuave, otro.marcaSuave),
      remitente: l(remitente, otro.remitente),
      sobreRemitente: l(sobreRemitente, otro.sobreRemitente),
      viajero: l(viajero, otro.viajero),
      sobreViajero: l(sobreViajero, otro.sobreViajero),
      exito: l(exito, otro.exito),
      exitoSuave: l(exitoSuave, otro.exitoSuave),
      atencion: l(atencion, otro.atencion),
      atencionSuave: l(atencionSuave, otro.atencionSuave),
      peligro: l(peligro, otro.peligro),
      peligroSuave: l(peligroSuave, otro.peligroSuave),
      info: l(info, otro.info),
      infoSuave: l(infoSuave, otro.infoSuave),
      conSombra: t < 0.5 ? conSombra : otro.conSombra,
    );
  }
}

extension ContextoTema on BuildContext {
  Colores get c => Theme.of(this).extension<Colores>()!;
  TextTheme get t => Theme.of(this).textTheme;
}

/// Degradados de la tarjeta principal (iguales en claro y oscuro; texto
/// blanco encima). Medianoche para el remitente y Cielo para el viajero.
abstract final class Degradados {
  static const remitente = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF3A5A8C), Color(0xFF1B2A4A), Color(0xFF0F1A30)],
    stops: [0, .42, 1],
  );

  static const viajero = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    // Más oscuro que el Cielo de los botones: texto blanco pequeño con AA.
    colors: [Color(0xFF1A5FB0), Color(0xFF0B4F9E), Color(0xFF083A75)],
    stops: [0, .42, 1],
  );

  static LinearGradient de(Rol rol) =>
      rol == Rol.remitente ? remitente : viajero;
}

/// Colores de íconos en recuadro pastel (el fondo es el color al 14 %).
abstract final class Pastel {
  static const azul = Color(0xFF3B82F6);
  static const violeta = Color(0xFF8B5CF6);
  static const ambar = Color(0xFFE8930C);
  static const rojo = Color(0xFFE5484D);
  static const verde = Color(0xFF1E8458);
  static const celeste = Color(0xFF0EA5E9);
}

/// Radios y medidas compartidas.
abstract final class Medidas {
  static const margen = 16.0;
  static const bloque = 20.0;
  static const radioCampo = 16.0;
  static const radioBoton = 16.0;
  static const radioTarjeta = 24.0;
  static const radioHero = 28.0;

  /// 52 en vez de 48 para que el toque siga ≥ 48 dp con letra grande.
  static const alturaBoton = 52.0;
  static const alturaBotonIcono = 48.0;
  static const alturaFila = 52.0;
  static const alturaTabbar = 62.0;

  /// Ancho máximo del contenido en tabletas / pantallas grandes.
  static const anchoMaximo = 480.0;

  /// Relleno inferior de una pestaña para que la barra flotante no tape el
  /// último contenido (docs/08 §8.6-7).
  static double bajoBarra(BuildContext context) =>
      alturaTabbar + MediaQuery.paddingOf(context).bottom + 24;
}

/// Curvas y duraciones del sistema. Con "reducir movimiento" se usa
/// [duracion] para llevarlas a cero.
abstract final class Movimiento {
  static const entrada = Cubic(0.22, 1, 0.36, 1);
  static const hoja = Cubic(0.32, 0.72, 0, 1);
  static const rapido = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 380);
  static const lento = Duration(milliseconds: 900);

  static Duration duracion(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Cifras tabulares para que las columnas de montos no "bailen".
const cifras = [FontFeature.tabularFigures()];

/// Tema de Lapticon v2: fuente del sistema para todo y Space Grotesk solo en
/// los estilos `display*` (ciudades del pase y cifras grandes).
ThemeData construirTema(Brightness brillo, {bool useGoogleFonts = true}) {
  final claro = brillo == Brightness.light;
  final c = claro ? Colores.claro : Colores.oscuro;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: Colores.claro.marcaSolido,
        brightness: brillo,
      ).copyWith(
        primary: c.marcaSolido,
        onPrimary: c.sobreMarca,
        primaryContainer: c.marcaSuave,
        onPrimaryContainer: c.marca,
        secondary: c.remitente,
        onSecondary: c.sobreRemitente,
        tertiary: c.viajero,
        onTertiary: c.sobreViajero,
        surface: c.fondo,
        onSurface: c.texto,
        onSurfaceVariant: c.texto2,
        surfaceContainerLowest: c.superficie,
        surfaceContainerLow: c.superficie,
        surfaceContainer: c.superficie,
        surfaceContainerHigh: c.superficie2,
        surfaceContainerHighest: c.superficie2,
        outline: c.texto3,
        outlineVariant: c.separador,
        error: c.peligro,
        errorContainer: c.peligroSuave,
        onErrorContainer: c.peligro,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: scheme,
  );
  final texto = _textos(base.textTheme, c, useGoogleFonts);

  return base.copyWith(
    textTheme: texto,
    scaffoldBackgroundColor: c.fondo,
    canvasColor: c.fondo,
    dividerColor: c.separador,
    extensions: [c],
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Barra de navegación estilo iOS (título grande que se compacta).
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brillo,
      primaryColor: c.marca,
      barBackgroundColor: c.fondo.withValues(alpha: .78),
      scaffoldBackgroundColor: c.fondo,
      textTheme: CupertinoTextThemeData(
        primaryColor: c.marca,
        textStyle: TextStyle(fontSize: 17, color: c.texto),
        actionTextStyle: TextStyle(fontSize: 17, color: c.marca),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: c.texto,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: c.texto,
        ),
        navActionTextStyle: TextStyle(fontSize: 17, color: c.marca),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.fondo,
      foregroundColor: c.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      // Barra de estado transparente: nada se difumina detrás.
      systemOverlayStyle:
          (claro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
    ),
    cardTheme: CardThemeData(
      color: c.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Medidas.alturaBoton),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioBoton),
        ),
        textStyle: texto.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Medidas.alturaBoton),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioBoton),
        ),
        side: BorderSide(color: c.separador),
        foregroundColor: c.texto,
        textStyle: texto.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: c.marca,
        textStyle: texto.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.superficie,
      indicatorColor: c.marcaSuave,
      labelTextStyle: WidgetStatePropertyAll(texto.labelMedium),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.superficie,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Medidas.radioHero),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioHero),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.texto,
      contentTextStyle: texto.bodyMedium?.copyWith(color: c.fondo),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioCampo),
      ),
    ),
    // Mismo gesto de volver en Android e iOS (docs/08 §8.8-4).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

TextTheme _textos(TextTheme base, Colores c, bool useGoogleFonts) {
  // Solo las funciones que devuelven TextStyle (no los helpers de TextTheme):
  // desde google_fonts 9 esos helpers usan el TextTheme de `material_ui`.
  TextStyle grotesk(TextStyle style) =>
      useGoogleFonts ? GoogleFonts.spaceGrotesk(textStyle: style) : style;

  final textos = base
      .copyWith(
        // Space Grotesk: cifra de la tarjeta principal y ciudades del pase.
        displayLarge: grotesk(
          const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            height: 1,
            fontFeatures: cifras,
          ),
        ),
        displayMedium: grotesk(
          const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        displaySmall: grotesk(
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        // Fuente del sistema para todo lo demás.
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 17, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 15, height: 1.35),
        bodySmall: const TextStyle(fontSize: 13),
        labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      )
      .apply(bodyColor: c.texto, displayColor: c.texto);

  // `apply` pinta todo con `texto`; los secundarios van con `texto2`.
  return textos.copyWith(
    bodyMedium: textos.bodyMedium?.copyWith(color: c.texto2),
    bodySmall: textos.bodySmall?.copyWith(color: c.texto2),
    labelMedium: textos.labelMedium?.copyWith(color: c.texto2),
    labelSmall: textos.labelSmall?.copyWith(color: c.texto2),
  );
}
