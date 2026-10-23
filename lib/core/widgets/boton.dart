import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// **primario** (la acción, uno por pantalla) · **tonal** (secundaria con
/// acento) · **secundario** (neutra) · **peligro** (destructiva).
enum VarianteBoton { primario, tonal, secundario, peligro }

/// Botón del sistema con estado de carga integrado: mientras [cargando] es
/// `true` muestra [textoCargando] ("Publicando…") y no responde, para evitar
/// el doble toque (docs/08 §8.6-2).
class Boton extends StatelessWidget {
  const Boton(
    this.texto, {
    super.key,
    required this.onTap,
    this.variante = VarianteBoton.primario,
    this.icono,
    this.cargando = false,
    this.textoCargando,
    this.chico = false,
    this.ancho = true,
  });

  final String texto;
  final VoidCallback? onTap;
  final VarianteBoton variante;
  final IconData? icono;
  final bool cargando;
  final String? textoCargando;

  /// Más bajo (40 dp visibles), pero con área táctil de 48 dp.
  final bool chico;

  /// Ocupa todo el ancho disponible.
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (fondo, frente) = switch (variante) {
      VarianteBoton.primario => (c.marcaSolido, c.sobreMarca),
      VarianteBoton.tonal => (c.marcaSuave, c.marca),
      VarianteBoton.secundario => (c.superficie2, c.texto),
      VarianteBoton.peligro => (c.peligroSuave, c.peligro),
    };
    final etiqueta = cargando ? (textoCargando ?? texto) : texto;

    final contenido = Row(
      mainAxisSize: ancho ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (cargando)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: frente),
          )
        else if (icono != null)
          Icon(icono, size: 20, color: frente),
        if (cargando || icono != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: chico ? 15 : 17,
              fontWeight: FontWeight.w600,
              color: frente,
            ),
          ),
        ),
      ],
    );

    final activo = onTap != null && !cargando;
    return Semantics(
      button: true,
      enabled: activo,
      label: etiqueta,
      onTap: activo ? onTap : null,
      excludeSemantics: true,
      child: Presionable(
        onTap: cargando ? null : onTap,
        atenuarInactivo: !cargando,
        child: Padding(
          // El área táctil llega a 48 dp aunque el botón chico mida 40.
          padding: EdgeInsets.symmetric(vertical: chico ? 4 : 0),
          child: Container(
            constraints: BoxConstraints(
              minHeight: chico ? 40 : Medidas.alturaBoton,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: chico ? 14 : 20,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(
                chico ? 12 : Medidas.radioBoton,
              ),
              boxShadow: variante == VarianteBoton.primario && c.conSombra
                  ? [
                      BoxShadow(
                        color: c.marcaSolido.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: contenido,
          ),
        ),
      ),
    );
  }
}
