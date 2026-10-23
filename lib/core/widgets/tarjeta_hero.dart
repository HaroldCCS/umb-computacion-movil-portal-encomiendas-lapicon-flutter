import 'package:flutter/material.dart';

import '../../data/models/rol.dart';
import '../theme/tema.dart';
import 'presionable.dart';
import 'progreso.dart';

/// Degradado de la barra de avance dentro de la tarjeta principal.
const degradadoProgreso = LinearGradient(
  colors: [Color(0xFFA7F3D0), Color(0xFF67E8F9)],
);

/// Tarjeta principal con degradado del rol (Medianoche / Cielo), brillo
/// arriba a la izquierda, cifra grande y sub-tarjetas de vidrio. Texto
/// blanco encima. Se llama `TarjetaHero` para no chocar con `Hero`.
class TarjetaHero extends StatelessWidget {
  const TarjetaHero({
    super.key,
    required this.rol,
    required this.titulo,
    required this.principal,
    this.nota,
    this.insignia,
    this.avance,
    this.etiquetaAvance,
    this.subTarjetas = const [],
    this.onTap,
    this.semantica,
  });

  final Rol rol;

  /// "Tus envíos activos", "Tu viaje".
  final String titulo;

  /// La cifra o texto grande (un `Text`, `Monto` o la ruta).
  final Widget principal;
  final String? nota;

  /// Etiqueta arriba a la derecha (p. ej. [EtiquetaVidrio] "Vuelo verificado").
  final Widget? insignia;

  /// 0..1; con [etiquetaAvance] muestra una barra.
  final double? avance;
  final String? etiquetaAvance;
  final List<Widget> subTarjetas;
  final VoidCallback? onTap;

  /// Resumen para el lector de pantalla; sin él, lee el contenido.
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    const blanco = Colors.white;
    final c = context.c;
    final contenido = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Medidas.radioHero),
        gradient: Degradados.de(rol),
        boxShadow: c.conSombra
            ? [
                BoxShadow(
                  color: Degradados.de(rol).colors[1].withValues(alpha: .45),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                  spreadRadius: -18,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Brillo arriba a la izquierda.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Medidas.radioHero),
                gradient: RadialGradient(
                  center: const Alignment(-1, -1),
                  radius: 1.1,
                  colors: [
                    blanco.withValues(alpha: .10),
                    blanco.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: blanco.withValues(alpha: .95),
                        ),
                      ),
                    ),
                    ?insignia,
                  ],
                ),
                const SizedBox(height: 6),
                DefaultTextStyle.merge(
                  style: context.t.displayLarge?.copyWith(color: blanco),
                  child: principal,
                ),
                if (nota != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    nota!,
                    style: TextStyle(
                      fontSize: 14,
                      color: blanco.withValues(alpha: .95),
                    ),
                  ),
                ],
                if (avance != null && etiquetaAvance != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          etiquetaAvance!.toUpperCase(),
                          style: _micro(.95),
                        ),
                      ),
                      Text('${(avance! * 100).round()} %', style: _micro(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Progreso(
                    avance!,
                    alto: 8,
                    fondo: blanco.withValues(alpha: .2),
                    degradado: degradadoProgreso,
                  ),
                ],
                if (subTarjetas.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < subTarjetas.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: subTarjetas[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final conSemantica = semantica == null
        ? contenido
        : Semantics(
            label: semantica,
            button: onTap != null,
            excludeSemantics: true,
            onTap: onTap,
            child: contenido,
          );
    if (onTap == null) return conSemantica;
    return Presionable(onTap: onTap, escala: 0.98, child: conSemantica);
  }
}

TextStyle _micro(double alfa) => TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
  color: Colors.white.withValues(alpha: alfa),
);

/// Sub-tarjeta "vidrio" dentro del hero: LLEVAS 2 / TE PAGAN USD 40.
class SubTarjetaVidrio extends StatelessWidget {
  const SubTarjetaVidrio({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.valor,
    this.tono = const Color(0xFFA7F3D0),
    this.onTap,
  });

  final String etiqueta;
  final IconData icono;

  /// Un `Text` o `Monto`; se pinta en blanco a 21 pt.
  final Widget valor;

  /// Color del ícono (verde menta, ámbar claro…).
  final Color tono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caja = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta - 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, size: 14, color: tono),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  etiqueta.toUpperCase(),
                  style: _micro(.95),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: cifras,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: valor,
          ),
        ],
      ),
    );
    if (onTap == null) return caja;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Presionable(onTap: onTap, escala: 0.96, child: caja),
      ),
    );
  }
}

/// Etiqueta en píldora de vidrio para usar sobre la tarjeta principal
/// ("Vuelo verificado"). Lleva ícono además del texto.
class EtiquetaVidrio extends StatelessWidget {
  const EtiquetaVidrio(this.texto, {super.key, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      border: Border.all(color: Colors.white.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
