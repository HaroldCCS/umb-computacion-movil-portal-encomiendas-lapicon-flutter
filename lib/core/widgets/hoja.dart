import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'boton.dart';
import 'confirmacion_escrita.dart';
import 'presionable.dart';

/// Hoja inferior del sistema: manija, título, botón cerrar; se cierra
/// arrastrando y sube con el teclado. Con [altoCompleto] ocupa casi toda la
/// pantalla y [contenido] maneja su propio scroll. Para formularios cortos y acciones con
/// consecuencias (docs/08 §8.6-5).
Future<T?> mostrarHoja<T>(
  BuildContext context, {
  required String titulo,
  required Widget contenido,
  bool altoCompleto = false,
}) {
  final animar = !MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .45),
    sheetAnimationStyle: animar
        ? const AnimationStyle(
            duration: Duration(milliseconds: 420),
            reverseDuration: Duration(milliseconds: 240),
            curve: Movimiento.hoja,
          )
        : AnimationStyle.noAnimation,
    builder: (context) =>
        _Hoja(titulo: titulo, contenido: contenido, altoCompleto: altoCompleto),
  );
}

class _Hoja extends StatelessWidget {
  const _Hoja({
    required this.titulo,
    required this.contenido,
    required this.altoCompleto,
  });

  final String titulo;
  final Widget contenido;

  /// Ocupa el alto máximo y el contenido maneja su propio scroll (listas
  /// largas como el buscador de países).
  final bool altoCompleto;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
          maxWidth: 560,
        ),
        child: Container(
          height: altoCompleto ? MediaQuery.sizeOf(context).height * .92 : null,
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Medidas.radioHero),
            ),
          ),
          padding: EdgeInsets.only(bottom: teclado),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.separador,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: c.texto,
                          ),
                        ),
                      ),
                    ),
                    _BotonCerrar(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              if (altoCompleto)
                Expanded(child: contenido)
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: contenido,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo de 32 dp con área táctil de 48 dp.
class _BotonCerrar extends StatelessWidget {
  const _BotonCerrar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: 'Cerrar',
      excludeSemantics: true,
      onTap: onTap,
      child: Presionable(
        onTap: onTap,
        escala: 0.9,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.superficie2,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 18, color: c.texto2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmación en hoja con verbo explícito. Devuelve `true` solo si se
/// confirma. Con [palabra], el botón se habilita al escribirla (acciones
/// irreversibles). Reemplaza a `confirmar()` con `AlertDialog`.
Future<bool> confirmarConHoja(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String confirmarTexto,
  String cancelarTexto = 'No, volver',
  bool destructivo = false,
  String? palabra,
  Widget? detalle,
}) async {
  final resultado = await mostrarHoja<bool>(
    context,
    titulo: titulo,
    contenido: _ContenidoConfirmacion(
      mensaje: mensaje,
      confirmarTexto: confirmarTexto,
      cancelarTexto: cancelarTexto,
      destructivo: destructivo,
      palabra: palabra,
      detalle: detalle,
    ),
  );
  return resultado ?? false;
}

class _ContenidoConfirmacion extends StatefulWidget {
  const _ContenidoConfirmacion({
    required this.mensaje,
    required this.confirmarTexto,
    required this.cancelarTexto,
    required this.destructivo,
    this.palabra,
    this.detalle,
  });

  final String mensaje;
  final String confirmarTexto;
  final String cancelarTexto;
  final bool destructivo;
  final String? palabra;
  final Widget? detalle;

  @override
  State<_ContenidoConfirmacion> createState() => _ContenidoConfirmacionState();
}

class _ContenidoConfirmacionState extends State<_ContenidoConfirmacion> {
  final _escrito = TextEditingController();

  @override
  void initState() {
    super.initState();
    _escrito.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _escrito.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final palabra = widget.palabra;
    final listo =
        palabra == null || ConfirmacionEscrita.coincide(_escrito.text, palabra);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.mensaje,
          style: TextStyle(fontSize: 17, height: 1.4, color: c.texto),
        ),
        if (widget.detalle != null) ...[
          const SizedBox(height: 16),
          widget.detalle!,
        ],
        if (palabra != null) ...[
          const SizedBox(height: 20),
          ConfirmacionEscrita(palabra: palabra, controlador: _escrito),
        ],
        const SizedBox(height: 24),
        Boton(
          widget.confirmarTexto,
          variante: widget.destructivo
              ? VarianteBoton.peligro
              : VarianteBoton.primario,
          onTap: listo ? () => Navigator.of(context).pop(true) : null,
        ),
        const SizedBox(height: 8),
        Boton(
          widget.cancelarTexto,
          variante: VarianteBoton.secundario,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
