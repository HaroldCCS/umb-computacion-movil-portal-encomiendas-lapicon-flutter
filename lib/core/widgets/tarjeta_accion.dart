import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'icono_en_caja.dart';
import 'tarjeta.dart';

/// Aviso que empuja a la acción ("Tu encomienda ya fue entregada · Califica
/// al viajero"): borde ámbar, ícono, dos líneas y flecha. Al tocarlo lleva
/// **directo** al lugar de la acción (docs/08 §8.4).
class TarjetaAccion extends StatelessWidget {
  const TarjetaAccion({
    super.key,
    required this.titulo,
    required this.texto,
    required this.onTap,
    this.icono = Icons.star_outline_rounded,
    this.color = Pastel.ambar,
  });

  final String titulo;
  final String texto;
  final VoidCallback onTap;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tarjeta(
      borde: c.atencion,
      onTap: onTap,
      child: Row(
        children: [
          IconoEnCaja(icono, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(texto, style: TextStyle(fontSize: 14, color: c.texto2)),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Icon(Icons.chevron_right_rounded, color: c.texto3),
          ),
        ],
      ),
    );
  }
}
