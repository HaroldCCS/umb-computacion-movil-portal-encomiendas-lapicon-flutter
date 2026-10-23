import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'boton.dart';
import 'tarjeta.dart';

enum TipoAviso { info, exito, atencion, error }

/// Mensaje en línea (info / éxito / atención / error). Los errores de una
/// acción van **junto a lo que la causó**, no en un mensaje genérico arriba
/// (docs/08 §8.6-2).
class Aviso extends StatelessWidget {
  const Aviso(
    this.texto, {
    super.key,
    this.titulo,
    this.tipo = TipoAviso.info,
    this.accion,
  });

  final String texto;
  final String? titulo;
  final TipoAviso tipo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (fondo, color, icono) = switch (tipo) {
      TipoAviso.info => (c.superficie2, c.texto2, Icons.info_outline_rounded),
      TipoAviso.exito => (c.exitoSuave, c.exito, Icons.check_rounded),
      TipoAviso.atencion => (
        c.atencionSuave,
        c.atencion,
        Icons.warning_amber_rounded,
      ),
      TipoAviso.error => (c.peligroSuave, c.peligro, Icons.error_outline),
    };
    // Sobre los fondos tintados el texto secundario va con el color del tipo
    // (texto2 no alcanza 4.5:1 sobre todos ellos).
    final colorTexto = tipo == TipoAviso.info ? c.texto2 : color;
    return Semantics(
      liveRegion: tipo == TipoAviso.error,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Medidas.radioCampo),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icono, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titulo != null)
                    Text(
                      titulo!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tipo == TipoAviso.info ? c.texto : color,
                      ),
                    ),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: colorTexto,
                    ),
                  ),
                  if (accion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: accion,
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

/// Estado vacío: ícono en círculo + título + texto + acción. Reemplaza a
/// `EmptyState`.
class Vacio extends StatelessWidget {
  const Vacio({
    super.key,
    required this.titulo,
    required this.icono,
    this.texto,
    this.accion,
    this.colorIcono,
    this.fondoIcono,
  });

  final String titulo;
  final IconData icono;
  final String? texto;
  final Widget? accion;

  /// Por defecto `marca` sobre `marcaSuave`.
  final Color? colorIcono;
  final Color? fondoIcono;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: fondoIcono ?? c.marcaSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colorIcono ?? c.marca, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: c.texto,
            ),
          ),
          if (texto != null) ...[
            const SizedBox(height: 8),
            Text(
              texto!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.35, color: c.texto2),
            ),
          ],
          if (accion != null) ...[const SizedBox(height: 20), accion!],
        ],
      ),
    );
  }
}

/// Error al cargar una pantalla, con mensaje humano y "Reintentar".
/// Reemplaza a `ErrorView`.
class ErrorCarga extends StatelessWidget {
  const ErrorCarga({
    super.key,
    required this.mensaje,
    required this.alReintentar,
    this.textoSecundario,
    this.alSecundario,
  });

  final String mensaje;
  final VoidCallback alReintentar;
  final String? textoSecundario;
  final VoidCallback? alSecundario;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      liveRegion: true,
      child: Vacio(
        titulo: 'No pudimos cargar la información',
        icono: Icons.cloud_off_outlined,
        texto: mensaje,
        colorIcono: c.peligro,
        fondoIcono: c.peligroSuave,
        accion: Column(
          children: [
            Boton(
              'Reintentar',
              icono: Icons.refresh_rounded,
              variante: VarianteBoton.tonal,
              onTap: alReintentar,
            ),
            if (textoSecundario != null && alSecundario != null) ...[
              const SizedBox(height: 8),
              Boton(
                textoSecundario!,
                variante: VarianteBoton.secundario,
                onTap: alSecundario,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
