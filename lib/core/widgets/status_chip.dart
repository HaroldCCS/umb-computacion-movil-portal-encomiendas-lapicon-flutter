import 'package:flutter/material.dart';

import '../../data/models/estado.dart';
import '../theme/app_tokens.dart';

/// Chip de estado: color + ícono + texto, nunca solo color (docs/07 §7.5).
class StatusChip extends StatelessWidget {
  const StatusChip._({
    required this.label,
    required this.icon,
    required this.color,
  });

  factory StatusChip.encomienda(EstadoEncomienda estado) {
    final (icon, color) = switch (estado) {
      EstadoEncomienda.disponible => (
        Icons.schedule,
        AppColors.estadoDisponible,
      ),
      EstadoEncomienda.tomada => (Icons.luggage, AppColors.estadoTomada),
      EstadoEncomienda.entregada => (
        Icons.check_circle,
        AppColors.estadoEntregada,
      ),
      EstadoEncomienda.vencida => (Icons.event_busy, AppColors.estadoVencida),
      EstadoEncomienda.recibida => (Icons.done_all, AppColors.estadoEntregada),
      EstadoEncomienda.desconocido => (
        Icons.help_outline,
        AppColors.estadoVencida,
      ),
    };
    return StatusChip._(label: estado.etiqueta, icon: icon, color: color);
  }

  factory StatusChip.viaje(EstadoViaje estado) {
    final (icon, color) = switch (estado) {
      EstadoViaje.disponible => (
        Icons.flight_takeoff,
        AppColors.estadoDisponible,
      ),
      EstadoViaje.completado => (Icons.flight_land, AppColors.estadoCompletado),
      EstadoViaje.desconocido => (Icons.help_outline, AppColors.estadoVencida),
    };
    return StatusChip._(label: estado.etiqueta, icon: icon, color: color);
  }

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // En modo oscuro se aclara el color para mantener el contraste.
    final fg = dark ? Color.lerp(color, Colors.white, 0.55)! : color;
    return Semantics(
      label: 'Estado: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: dark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
