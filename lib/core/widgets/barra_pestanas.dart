import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// Una pestaña de [BarraPestanas]. El [contador] avisa de algo por hacer
/// (no se muestra en 0) y [etiquetaContador] lo explica al lector de
/// pantalla ("2 por calificar").
class PestanaItem {
  const PestanaItem(
    this.icono,
    this.texto, {
    this.iconoActivo,
    this.contador = 0,
    this.etiquetaContador,
  });

  final IconData icono;
  final IconData? iconoActivo;
  final String texto;
  final int contador;
  final String? etiquetaContador;
}

/// Píldora flotante de vidrio con las secciones y, aparte, el botón
/// circular de la acción principal. Sin [onMas] el botón no se muestra y la
/// píldora ocupa todo el ancho (docs/08 §8.4: no mostrar lo que no aplica).
///
/// Se usa con `Scaffold(extendBody: true)` y cada pestaña deja
/// `Medidas.bajoBarra(context)` de relleno inferior.
class BarraPestanas extends StatelessWidget {
  const BarraPestanas({
    super.key,
    required this.items,
    required this.actual,
    required this.onCambio,
    this.onMas,
    this.etiquetaMas = 'Crear',
  });

  final List<PestanaItem> items;
  final int actual;
  final ValueChanged<int> onCambio;
  final VoidCallback? onMas;
  final String etiquetaMas;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const alto = Medidas.alturaTabbar;
    // La barra tiene alto fijo: la letra crece hasta 1.3× y no más.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Medidas.margen,
          0,
          Medidas.margen,
          MediaQuery.paddingOf(context).bottom + 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: alto,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.superficie.withValues(alpha: .86),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.separador),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _Pestana(
                              item: items[i],
                              activa: i == actual,
                              posicion: '${i + 1} de ${items.length}',
                              onTap: () => onCambio(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onMas != null) ...[
              const SizedBox(width: 12),
              Tooltip(
                message: etiquetaMas,
                child: Semantics(
                  button: true,
                  label: etiquetaMas,
                  onTap: onMas,
                  excludeSemantics: true,
                  child: Presionable(
                    onTap: onMas,
                    escala: 0.9,
                    haptico: true,
                    child: Container(
                      width: alto,
                      height: alto,
                      decoration: BoxDecoration(
                        color: c.marcaSolido,
                        shape: BoxShape.circle,
                        boxShadow: c.conSombra
                            ? [
                                BoxShadow(
                                  color: c.marcaSolido.withValues(alpha: .3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 30,
                        color: c.sobreMarca,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.item,
    required this.activa,
    required this.posicion,
    required this.onTap,
  });

  final PestanaItem item;
  final bool activa;
  final String posicion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = activa ? c.marca : c.texto2;
    final animar = !MediaQuery.disableAnimationsOf(context);
    final contador = item.contador > 0
        ? ', ${item.etiquetaContador ?? '${item.contador} pendientes'}'
        : '';
    return Semantics(
      selected: activa,
      button: true,
      label: '${item.texto}$contador, pestaña $posicion',
      onTap: onTap,
      excludeSemantics: true,
      child: Presionable(
        onTap: onTap,
        escala: 0.9,
        child: AnimatedContainer(
          duration: animar ? const Duration(milliseconds: 200) : Duration.zero,
          decoration: BoxDecoration(
            color: activa ? c.marcaSuave : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    activa ? (item.iconoActivo ?? item.icono) : item.icono,
                    color: color,
                    size: 24,
                  ),
                  if (item.contador > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: _Contador(valor: item.contador, animar: animar),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Burbuja roja con el número; rebota cada vez que cambia.
class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.animar});

  final int valor;
  final bool animar;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final burbuja = Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: c.peligro,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.superficie, width: 2),
      ),
      child: Text(
        valor > 99 ? '99+' : '$valor',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c.superficie,
        ),
      ),
    );
    if (!animar) return burbuja;
    return TweenAnimationBuilder<double>(
      key: ValueKey(valor),
      tween: Tween(begin: 1.18, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, s, hijo) => Transform.scale(scale: s, child: hijo),
      child: burbuja,
    );
  }
}
