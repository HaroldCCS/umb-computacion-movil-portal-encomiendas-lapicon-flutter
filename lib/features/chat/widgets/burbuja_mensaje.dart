import 'package:flutter/material.dart';

import '../../../core/theme/tema.dart';
import '../../../core/utils/formatters.dart';
import '../models/mensaje_chat.dart';

/// Forma de las burbujas de chat (también la usa el asistente): esquina
/// casi recta del lado de quien habla.
BorderRadius formaBurbuja({required bool propia}) {
  const radio = Radius.circular(20);
  const pico = Radius.circular(6);
  return BorderRadius.only(
    topLeft: radio,
    topRight: radio,
    bottomLeft: propia ? radio : pico,
    bottomRight: propia ? pico : radio,
  );
}

/// Burbuja de mensaje: propias a la derecha en `marcaSolido`, ajenas a la
/// izquierda en `superficie`.
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
    final c = context.c;
    final fondo = propio ? c.marcaSolido : c.superficie;
    final texto = propio ? c.sobreMarca : c.texto;
    final secundario = propio ? c.sobreMarca.withValues(alpha: 0.85) : c.texto2;
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
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: formaBurbuja(propia: propio),
              border: propio || c.conSombra
                  ? null
                  : Border.all(color: c.separador),
              boxShadow: propio ? null : c.sombraTarjeta,
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
                    style: TextStyle(fontSize: 17, height: 1.35, color: texto),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hora,
                      style: TextStyle(
                        fontSize: 12,
                        color: secundario,
                        fontFeatures: cifras,
                      ),
                    ),
                    if (propio) ...[
                      const SizedBox(width: 4),
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
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: c.superficie2,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.texto2,
            ),
          ),
        ),
      ),
    );
  }
}
