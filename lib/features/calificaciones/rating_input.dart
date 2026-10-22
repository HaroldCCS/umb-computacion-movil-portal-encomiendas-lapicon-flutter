import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Etiqueta de cada puntaje (docs/07 §7.6 "Calificar").
String etiquetaPuntaje(int puntaje) => switch (puntaje) {
  1 => 'Malo',
  2 => 'Regular',
  3 => 'Bueno',
  4 => 'Muy bueno',
  5 => 'Excelente',
  _ => '',
};

/// Sugerencias rápidas según el puntaje elegido.
List<String> sugerenciasPara(int puntaje) {
  if (puntaje <= 0) return const [];
  if (puntaje >= 4) {
    return const [
      'Puntual',
      'Buena comunicación',
      'Cuidó el paquete',
      'Amable',
    ];
  }
  return const [
    'Llegó tarde',
    'Poca comunicación',
    'Paquete con daños',
    'Difícil de coordinar',
  ];
}

/// Une las sugerencias elegidas y el texto libre en un solo comentario
/// (máximo [maxLength] caracteres).
String componerComentario(
  Iterable<String> sugerencias,
  String texto, {
  int maxLength = 300,
}) {
  final partes = [
    ...sugerencias.map((s) => s.trim()).where((s) => s.isNotEmpty),
    if (texto.trim().isNotEmpty) texto.trim(),
  ];
  final unido = partes.join('. ');
  return unido.length <= maxLength ? unido : unido.substring(0, maxLength);
}

/// Entrada de calificación: 5 estrellas grandes (≥ 48 dp), accesible como
/// control ajustable y con etiqueta del puntaje elegido.
class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.starSize = 44,
  });

  /// 0 = sin elegir, 1..5.
  final int value;
  final ValueChanged<int> onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    final animar = !MediaQuery.disableAnimationsOf(context);
    final duracion = animar ? const Duration(milliseconds: 180) : Duration.zero;

    return Semantics(
      label: 'Calificación',
      value: value == 0 ? 'Sin calificar' : '$value de 5 estrellas',
      increasedValue: '${(value + 1).clamp(1, 5)} de 5 estrellas',
      decreasedValue: '${(value - 1).clamp(1, 5)} de 5 estrellas',
      onIncrease: value < 5 ? () => onChanged(value + 1) : null,
      onDecrease: value > 1 ? () => onChanged(value - 1) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  button: true,
                  selected: i <= value,
                  label: '$i de 5 estrellas',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: starSize + 12,
                    height: starSize + 12,
                    child: InkResponse(
                      radius: (starSize + 12) / 2,
                      onTap: () => onChanged(i),
                      child: AnimatedScale(
                        scale: i <= value ? 1.08 : 1,
                        duration: duracion,
                        curve: Curves.easeOutBack,
                        child: Icon(
                          i <= value
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: starSize,
                          color: i <= value ? color : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: duracion,
            child: Text(
              value == 0 ? 'Toca una estrella' : etiquetaPuntaje(value),
              key: ValueKey(value),
              style: value == 0
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
