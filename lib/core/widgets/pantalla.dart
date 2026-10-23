import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'entrada.dart';

/// Pantalla estilo iOS (docs/08 §8.8-4): título grande que se compacta en
/// una barra de vidrio al hacer scroll, rebote y "jalar para actualizar".
///
/// El contenido va en [hijos] (columna con separación de bloque y entrada
/// escalonada) o, para listas largas, en [slivers]. [pie] queda fijo abajo
/// (p. ej. la acción principal de un detalle).
class Pantalla extends StatelessWidget {
  const Pantalla({
    super.key,
    required this.titulo,
    this.hijos = const [],
    this.slivers = const [],
    this.subtitulo,
    this.accion,
    this.textoAtras,
    this.alActualizar,
    this.conBarraPestanas = false,
    this.cabecera,
    this.pie,
    this.controlador,
  });

  final String titulo;
  final List<Widget> hijos;
  final List<Widget> slivers;
  final String? subtitulo;

  /// Acción a la derecha de la barra (p. ej. un [BotonIcono]).
  final Widget? accion;

  /// Texto junto a la flecha de volver ("Envíos"). Sin él, solo la flecha.
  final String? textoAtras;
  final Future<void> Function()? alActualizar;

  /// Es una pestaña de la barra flotante: deja espacio para no taparla.
  final bool conBarraPestanas;

  /// Contenido fijo arriba del cuerpo, debajo del subtítulo (p. ej. Chips).
  final Widget? cabecera;
  final Widget? pie;
  final ScrollController? controlador;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final abajo = conBarraPestanas
        ? Medidas.bajoBarra(context)
        : (pie == null ? MediaQuery.paddingOf(context).bottom + 24 : 24.0);

    return Scaffold(
      backgroundColor: c.fondo,
      body: CustomScrollView(
        controller: controlador,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(titulo),
            previousPageTitle: textoAtras,
            trailing: accion,
            backgroundColor: c.fondo.withValues(alpha: .78),
            border: Border(
              bottom: BorderSide(
                color: c.separador.withValues(alpha: .7),
                width: .5,
              ),
            ),
            // Con jalar para actualizar, el estiramiento se lo come el gesto.
            stretch: alActualizar == null,
          ),
          if (alActualizar != null)
            CupertinoSliverRefreshControl(onRefresh: alActualizar),
          if (subtitulo != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margen,
                0,
                Medidas.margen,
                4,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  subtitulo!,
                  style: TextStyle(fontSize: 15, color: c.texto2),
                ),
              ),
            ),
          if (cabecera != null)
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverToBoxAdapter(child: cabecera),
            ),
          if (hijos.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Medidas.margen,
                16,
                Medidas.margen,
                slivers.isEmpty ? abajo : 0,
              ),
              sliver: SliverList.separated(
                itemCount: hijos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Medidas.bloque),
                itemBuilder: (_, i) => Entrada(indice: i, child: hijos[i]),
              ),
            ),
          ...slivers,
          if (slivers.isNotEmpty)
            SliverPadding(padding: EdgeInsets.only(bottom: abajo)),
        ],
      ),
      bottomNavigationBar: pie == null ? null : _Pie(child: pie!),
    );
  }
}

/// Franja fija inferior sobre el fondo, con línea fina arriba.
class _Pie extends StatelessWidget {
  const _Pie({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.fondo,
        border: Border(top: BorderSide(color: c.separador, width: .5)),
      ),
      padding: EdgeInsets.fromLTRB(
        Medidas.margen,
        12,
        Medidas.margen,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: child,
    );
  }
}
