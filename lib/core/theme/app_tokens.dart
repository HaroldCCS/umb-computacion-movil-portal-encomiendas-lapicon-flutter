import 'package:flutter/material.dart';

import '../../data/models/rol.dart';

/// Tokens del sistema de diseño (docs/07-diseno-ux-ui.md §7.5).
abstract final class AppColors {
  // Marca
  static const midnight = Color(0xFF1B2A4A);
  static const amber = Color(0xFFF2A93B);
  static const sky = Color(0xFF0B63C4); // apto para texto y rellenos
  static const skyDecorative = Color(0xFF2D8CFF); // solo decorativo
  static const paper = Color(0xFFF7F5F0);

  // Modo oscuro
  static const midnightDark = Color(0xFFAFC6FF);
  static const amberDark = Color(0xFFFFC56E);
  static const skyDark = Color(0xFF8CC4FF);
  static const surfaceDark = Color(0xFF11141B);

  // Estados (contraste ≥ 4.9:1 sobre blanco y papel)
  static const estadoDisponible = Color(0xFF0D47A1);
  static const estadoTomada = Color(0xFF8A4B00);
  static const estadoEntregada = Color(0xFF1B5E20);
  static const estadoVencida = Color(0xFF5F5F5F);
  static const estadoCancelada = Color(0xFFB71C1C);
  static const estadoCompletado = Color(0xFF455A64);
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

  /// Ancho máximo del contenido en tabletas / pantallas grandes.
  static const maxContentWidth = 480.0;
}

abstract final class AppRadius {
  static const field = 12.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

/// Color de acento de cada rol: ámbar (paquete) y cielo (avión).
extension RolVisual on Rol {
  Color accent(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      Rol.remitente => dark ? AppColors.amberDark : AppColors.amber,
      Rol.viajero => dark ? AppColors.skyDark : AppColors.sky,
    };
  }

  /// Color del texto/ícono encima de [accent].
  Color onAccent(Brightness brightness) {
    if (brightness == Brightness.dark) return AppColors.surfaceDark;
    return switch (this) {
      Rol.remitente => AppColors.midnight,
      Rol.viajero => Colors.white,
    };
  }

  IconData get icon => switch (this) {
    Rol.remitente => Icons.inventory_2_outlined,
    Rol.viajero => Icons.flight_takeoff,
  };
}
