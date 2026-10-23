import 'package:flutter/material.dart';

import 'tema.dart';

/// Alias temporal de [construirTema] mientras las pantallas migran al
/// sistema v2 (docs/08 §8.7, fase 1). Se borra en la fase 6.
abstract final class AppTheme {
  static ThemeData light({bool useGoogleFonts = true}) =>
      construirTema(Brightness.light, useGoogleFonts: useGoogleFonts);

  static ThemeData dark({bool useGoogleFonts = true}) =>
      construirTema(Brightness.dark, useGoogleFonts: useGoogleFonts);
}
