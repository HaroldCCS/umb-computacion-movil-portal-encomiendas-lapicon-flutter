import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../models/mensaje_chat.dart';

/// Burbuja de mensaje: propias a la derecha en `primary`, ajenas a la
/// izquierda en `surfaceContainerLowest` con borde (docs/07 §7.6).
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({
    super.key,
    required this.mensaje,
    required this.propio,
    required this.nombreOtro,
  });

  final MensajeChat mensaje;
  final bool propio;
  final String nombreOtro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fondo = propio ? scheme.primary : scheme.surfaceContainerLowest;
    final texto = propio ? scheme.onPrimary : scheme.onSurface;
    final secundario = propio
        ? scheme.onPrimary.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;
    const radio = Radius.circular(18);
    final hora = mensaje.pendiente ? 'Enviando…' : Fmt.hora(mensaje.fecha);

    return Semantics(
      label: '${propio ? 'Tú' : nombreOtro}: ${mensaje.texto}. $hora',
      excludeSemantics: true,
      child: Align(
        alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm + 2,
              AppSpacing.xs + 2,
              AppSpacing.sm + 2,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: fondo,
              border: propio ? null : Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.only(
                topLeft: radio,
                topRight: radio,
                bottomLeft: propio ? radio : const Radius.circular(4),
                bottomRight: propio ? const Radius.circular(4) : radio,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Text(
                    mensaje.texto,
                    style: theme.textTheme.bodyLarge?.copyWith(color: texto),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hora,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secundario,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (propio) ...[
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(
                        mensaje.pendiente ? Icons.schedule : Icons.done,
                        size: 14,
                        color: secundario,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Separador centrado con el día ("Hoy", "Ayer", "3 oct").
class SeparadorDiaView extends StatelessWidget {
  const SeparadorDiaView({super.key, required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            etiqueta,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
