import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'campo.dart';

/// Para acciones irreversibles: hay que escribir [palabra] para habilitar el
/// botón. Un toque se da sin pensar; escribir obliga a leer (docs/08 §8.6-5).
class ConfirmacionEscrita extends StatelessWidget {
  const ConfirmacionEscrita({
    super.key,
    required this.palabra,
    required this.controlador,
  });

  final String palabra;
  final TextEditingController controlador;

  /// ¿Lo escrito coincide con [palabra]? (sin importar mayúsculas).
  static bool coincide(String escrito, String palabra) =>
      escrito.trim().toUpperCase() == palabra.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: c.texto2),
              children: [
                const TextSpan(text: 'Para confirmar, escribe '),
                TextSpan(
                  text: palabra,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.texto,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          label: 'Escribe $palabra para confirmar',
          child: TextField(
            controller: controlador,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              fontSize: 17,
              letterSpacing: 3,
              fontFamily: 'monospace',
              color: c.texto,
            ),
            decoration: decoracionCampo(context, pista: palabra),
          ),
        ),
      ],
    );
  }
}
