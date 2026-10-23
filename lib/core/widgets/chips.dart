import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// Opción de [Chips]: valor, texto y contador opcional (no se muestra en 0).
typedef OpcionChip<T> = (T valor, String texto, int? contador);

/// Pestañas en píldora con la activa en negro (en oscuro, en blanco).
/// Reemplaza `TabBar`, `SegmentedButton` y `FilterChip` de selección única.
class Chips<T> extends StatelessWidget {
  const Chips({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onCambio,
    this.relleno = const EdgeInsets.symmetric(horizontal: Medidas.margen),
  });

  final List<OpcionChip<T>> opciones;
  final T valor;
  final ValueChanged<T> onCambio;
  final EdgeInsetsGeometry relleno;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final duracion = Movimiento.duracion(
      context,
      const Duration(milliseconds: 200),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: relleno,
      child: Row(
        children: [
          for (final (v, texto, contador) in opciones)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                selected: v == valor,
                label: (contador ?? 0) > 0 ? '$texto, $contador' : texto,
                excludeSemantics: true,
                onTap: () => onCambio(v),
                child: Presionable(
                  escala: 0.95,
                  onTap: () => onCambio(v),
                  // 40 dp visibles, 48 dp de área táctil.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AnimatedContainer(
                      duration: duracion,
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: v == valor ? c.texto : c.superficie,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: v == valor ? c.texto : c.separador,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            texto,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: v == valor ? c.fondo : c.texto2,
                            ),
                          ),
                          if ((contador ?? 0) > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.atencion,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$contador',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.superficie,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
