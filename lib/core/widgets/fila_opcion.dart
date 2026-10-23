import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// Fila de una lista de selección (país, ciudad): texto, ícono opcional y
/// check en la elegida (no solo color).
class FilaOpcion extends StatelessWidget {
  const FilaOpcion({
    super.key,
    required this.texto,
    required this.seleccionada,
    required this.onTap,
    this.icono,
  });

  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: seleccionada,
      label: texto,
      onTap: onTap,
      excludeSemantics: true,
      child: Presionable(
        onTap: onTap,
        escala: 0.99,
        child: Container(
          constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.separador)),
          ),
          child: Row(
            children: [
              if (icono != null) ...[
                Icon(icono, color: c.texto2, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: seleccionada ? FontWeight.w600 : null,
                    color: seleccionada ? c.marca : c.texto,
                  ),
                ),
              ),
              if (seleccionada) Icon(Icons.check_rounded, color: c.marca),
            ],
          ),
        ),
      ),
    );
  }
}
