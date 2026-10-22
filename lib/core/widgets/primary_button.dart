import 'package:flutter/material.dart';

/// Botón principal (uno por pantalla). Muestra un indicador mientras
/// [loading] es `true` y se deshabilita para evitar envíos dobles.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.onPrimary,
              semanticsLabel: 'Cargando',
            ),
          )
        : Text(label);

    return Semantics(
      button: true,
      label: loading ? '$label, cargando' : null,
      excludeSemantics: loading,
      child: icon == null || loading
          ? FilledButton(onPressed: loading ? null : onPressed, child: child)
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: child,
            ),
    );
  }
}
