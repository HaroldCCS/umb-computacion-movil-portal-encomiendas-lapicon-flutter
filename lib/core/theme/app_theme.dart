import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Tema Material 3 de Lapticon: Medianoche + Ámbar + Cielo sobre papel.
/// Títulos y ciudades en Space Grotesk; texto en Manrope.
abstract final class AppTheme {
  static ThemeData light({bool useGoogleFonts = true}) =>
      _build(Brightness.light, useGoogleFonts);

  static ThemeData dark({bool useGoogleFonts = true}) =>
      _build(Brightness.dark, useGoogleFonts);

  static ThemeData _build(Brightness brightness, bool useGoogleFonts) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.midnight,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.midnightDark : AppColors.midnight,
          onPrimary: isDark ? const Color(0xFF0E1A33) : Colors.white,
          secondary: isDark ? AppColors.amberDark : AppColors.amber,
          onSecondary: isDark ? AppColors.surfaceDark : AppColors.midnight,
          tertiary: isDark ? AppColors.skyDark : AppColors.sky,
          onTertiary: isDark ? const Color(0xFF00213F) : Colors.white,
          surface: isDark ? AppColors.surfaceDark : AppColors.paper,
          surfaceContainerLowest: isDark
              ? const Color(0xFF0C0F15)
              : Colors.white,
          error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFC62828),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = _textTheme(base.textTheme, scheme, useGoogleFonts);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      dividerColor: scheme.outlineVariant,
    );
  }

  static TextTheme _textTheme(
    TextTheme base,
    ColorScheme scheme,
    bool useGoogleFonts,
  ) {
    // Se usan solo las funciones que devuelven TextStyle (no los helpers de
    // TextTheme): desde google_fonts 9 esos helpers usan el TextTheme del
    // paquete `material_ui`, que es un tipo distinto al de flutter/material.
    TextStyle? display(TextStyle? style) =>
        useGoogleFonts ? GoogleFonts.spaceGrotesk(textStyle: style) : style;
    TextStyle? text(TextStyle? style) =>
        useGoogleFonts ? GoogleFonts.manrope(textStyle: style) : style;

    final body = base.copyWith(
      displayLarge: text(base.displayLarge),
      displayMedium: text(base.displayMedium),
      displaySmall: text(base.displaySmall),
      headlineLarge: text(base.headlineLarge),
      headlineMedium: text(base.headlineMedium),
      headlineSmall: text(base.headlineSmall),
      titleLarge: text(base.titleLarge),
      titleMedium: text(base.titleMedium),
      titleSmall: text(base.titleSmall),
      bodyLarge: text(base.bodyLarge),
      bodyMedium: text(base.bodyMedium),
      bodySmall: text(base.bodySmall),
      labelLarge: text(base.labelLarge),
      labelMedium: text(base.labelMedium),
      labelSmall: text(base.labelSmall),
    );

    return body
        .copyWith(
          displaySmall: display(
            body.displaySmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          headlineMedium: display(
            body.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          headlineSmall: display(
            body.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          titleLarge: display(
            body.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
          bodyMedium: body.bodyMedium?.copyWith(height: 1.4),
          labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          labelSmall: display(
            body.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
