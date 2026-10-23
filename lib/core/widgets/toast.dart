import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tema.dart';

enum TipoToast { exito, error, info }

/// Muestra un aviso flotante que cae desde arriba y se va solo (3,2 s).
/// Todo éxito se confirma así (docs/08 §8.6-2). Si no hay [Toasts] arriba
/// en el árbol (p. ej. en una prueba aislada), usa un SnackBar.
void mostrarToast(
  BuildContext context,
  String texto, {
  TipoToast tipo = TipoToast.exito,
}) {
  final toasts = context.findAncestorStateOfType<_ToastsState>();
  if (toasts != null) {
    toasts.mostrar(texto, tipo);
    return;
  }
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Capa de avisos flotantes. Va en `MaterialApp.builder`, por encima del
/// Navigator, para que se vea también sobre hojas y diálogos.
class Toasts extends StatefulWidget {
  const Toasts({super.key, required this.child});

  final Widget child;

  static const duracion = Duration(milliseconds: 3200);

  @override
  State<Toasts> createState() => _ToastsState();
}

class _ToastsState extends State<Toasts> {
  final _lista = <(int, String, TipoToast)>[];
  final _timers = <Timer>[];
  var _id = 0;

  void mostrar(String texto, TipoToast tipo) {
    final id = _id++;
    setState(() {
      // Como mucho tres a la vez: el más viejo se va primero.
      if (_lista.length == 3) _lista.removeAt(0);
      _lista.add((id, texto, tipo));
    });
    _timers.add(Timer(Toasts.duracion, () => _quitar(id)));
  }

  void _quitar(int id) {
    if (mounted) setState(() => _lista.removeWhere((t) => t.$1 == id));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duracion = Movimiento.duracion(
      context,
      const Duration(milliseconds: 360),
    );
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: Medidas.margen,
          right: Medidas.margen,
          top: MediaQuery.paddingOf(context).top + 10,
          child: Column(
            children: [
              for (final (id, texto, tipo) in _lista)
                TweenAnimationBuilder<double>(
                  key: ValueKey(id),
                  tween: Tween(begin: 0, end: 1),
                  duration: duracion,
                  curve: Movimiento.entrada,
                  builder: (_, v, hijo) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, -16 * (1 - v)),
                      child: hijo,
                    ),
                  ),
                  child: _Toast(
                    texto: texto,
                    tipo: tipo,
                    alCerrar: () => _quitar(id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({
    required this.texto,
    required this.tipo,
    required this.alCerrar,
  });

  final String texto;
  final TipoToast tipo;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (icono, color) = switch (tipo) {
      TipoToast.exito => (Icons.check_circle_rounded, c.exito),
      TipoToast.error => (Icons.error_outline_rounded, c.peligro),
      TipoToast.info => (Icons.info_outline_rounded, c.marca),
    };
    return Semantics(
      liveRegion: true,
      child: GestureDetector(
        onTap: alCerrar, // tocarlo lo descarta
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Medidas.radioCampo),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Material(
                // Casi opaco: el texto no pierde contraste con lo de atrás.
                color: c.superficie.withValues(alpha: .94),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.separador),
                    borderRadius: BorderRadius.circular(Medidas.radioCampo),
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(icono, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          texto,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: c.texto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
