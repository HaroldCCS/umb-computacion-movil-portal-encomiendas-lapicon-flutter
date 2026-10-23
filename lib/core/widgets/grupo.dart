import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'icono_en_caja.dart';
import 'presionable.dart';

/// Lista agrupada estilo iOS: filas en una tarjeta separadas por una línea
/// fina, con título en mayúsculas arriba y nota opcional abajo.
class Grupo extends StatelessWidget {
  const Grupo({super.key, required this.hijos, this.titulo, this.pie});

  final List<Widget> hijos;
  final String? titulo;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo != null)
          Padding(
            padding: const EdgeInsets.only(left: Medidas.margen, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                titulo!.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: c.texto2,
                ),
              ),
            ),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            boxShadow: c.sombraTarjeta,
            border: c.conSombra ? null : Border.all(color: c.separador),
          ),
          child: Column(
            children: [
              for (var i = 0; i < hijos.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.separador),
                hijos[i],
              ],
            ],
          ),
        ),
        if (pie != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Medidas.margen, 8, 16, 0),
            child: Text(pie!, style: TextStyle(fontSize: 13, color: c.texto2)),
          ),
      ],
    );
  }
}

/// Fila etiqueta → valor, con explicación opcional debajo del valor
/// ("nunca un número solo").
class Fila extends StatelessWidget {
  const Fila(this.etiqueta, this.valor, {super.key, this.extra});

  final String etiqueta;
  final Widget valor;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: TextStyle(fontSize: 15, color: c.texto2)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.texto,
                    ),
                    textAlign: TextAlign.right,
                    child: valor,
                  ),
                  if (extra != null)
                    Text(
                      extra!,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: c.texto2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila que lleva a otra pantalla o hace una acción (estilo ajustes):
/// ícono en caja, título, subtítulo y flecha.
class FilaAccion extends StatelessWidget {
  const FilaAccion({
    super.key,
    required this.titulo,
    required this.onTap,
    this.icono,
    this.colorIcono,
    this.subtitulo,
    this.destructiva = false,
    this.flecha = true,
  });

  final String titulo;
  final VoidCallback? onTap;
  final IconData? icono;
  final Color? colorIcono;
  final String? subtitulo;

  /// Texto en rojo (cerrar sesión, retirar…).
  final bool destructiva;
  final bool flecha;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colorTitulo = destructiva ? c.peligro : c.texto;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Presionable(
          onTap: onTap,
          escala: 0.99,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (icono != null) ...[
                    IconoEnCaja(
                      icono!,
                      color: destructiva ? c.peligro : (colorIcono ?? c.marca),
                      tam: 36,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: colorTitulo,
                          ),
                        ),
                        if (subtitulo != null)
                          Text(
                            subtitulo!,
                            style: TextStyle(fontSize: 13, color: c.texto2),
                          ),
                      ],
                    ),
                  ),
                  if (flecha && !destructiva)
                    ExcludeSemantics(
                      child: Icon(Icons.chevron_right_rounded, color: c.texto3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
