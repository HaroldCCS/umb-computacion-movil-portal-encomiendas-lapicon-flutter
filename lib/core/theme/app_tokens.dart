import 'package:flutter/material.dart';

import '../../data/models/rol.dart';
import 'tema.dart';

// Alias temporales de los tokens v1 que apuntan a los valores v2 de
// `tema.dart` (docs/08 §8.7, fase 1). Se borran en la fase 6: el código nuevo
// usa `context.c`, `Medidas` y `Movimiento`.

abstract final class AppColors {
  // Marca
  static const midnight = Color(0xFF1B2A4A);
  static const amber = Color(0xFFF2A93B);
  static const sky = Color(0xFF0B63C4);
  static const skyDecorative = Color(0xFF2D8CFF);
  static const paper = Color(0xFFF5F6F8);

  // Modo oscuro
  static const midnightDark = Color(0xFFAFC6FF);
  static const amberDark = Color(0xFFFFC56E);
  static const skyDark = Color(0xFF8CC4FF);
  static const surfaceDark = Color(0xFF000000);

  // Estados (los mismos valores que `Colores.claro`)
  static const estadoDisponible = Color(0xFF0D47A1);
  static const estadoTomada = Color(0xFF8A4B00);
  static const estadoEntregada = Color(0xFF17663F);
  static const estadoVencida = Color(0xFF5C6678);
  static const estadoCancelada = Color(0xFFC62828);
  static const estadoCompletado = Color(0xFF5C6678);
}

/// Retícula de 4 dp.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const maxContentWidth = Medidas.anchoMaximo;
}

abstract final class AppRadius {
  static const field = Medidas.radioCampo;
  static const card = Medidas.radioTarjeta;
  static const sheet = Medidas.radioHero;
}

/// Color de acento de cada rol: ámbar (paquete) y cielo (avión).
extension RolVisual on Rol {
  Color accent(Brightness brightness) => _colores(brightness).acento(this);

  /// Color del texto/ícono encima de [accent].
  Color onAccent(Brightness brightness) =>
      _colores(brightness).sobreAcento(this);

  IconData get icon => switch (this) {
    Rol.remitente => Icons.inventory_2_outlined,
    Rol.viajero => Icons.flight_takeoff,
  };
}

Colores _colores(Brightness b) =>
    b == Brightness.dark ? Colores.oscuro : Colores.claro;
