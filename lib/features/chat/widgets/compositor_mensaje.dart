import 'package:flutter/material.dart';

import '../../../core/theme/tema.dart';
import '../../../core/widgets/presionable.dart';

/// Barra inferior para escribir (chat y asistente). Si [cerrado], se muestra
/// deshabilitada con la explicación (reto 4: bloquear el envío cuando el chat
/// se cierra).
class CompositorMensaje extends StatefulWidget {
  const CompositorMensaje({
    super.key,
    required this.onEnviar,
    this.cerrado = false,
    this.enviando = false,
    this.pista = 'Escribe un mensaje',
    this.textoCerrado = 'Este chat se cerró porque la entrega terminó.',
  });

  /// Devuelve `true` si el mensaje se envió (para limpiar el campo).
  final Future<bool> Function(String texto) onEnviar;
  final bool cerrado;
  final bool enviando;
  final String pista;
  final String textoCerrado;

  static const maxCaracteres = 500;

  @override
  State<CompositorMensaje> createState() => _CompositorMensajeState();
}

class _CompositorMensajeState extends State<CompositorMensaje> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || widget.enviando) return;
    final ok = await widget.onEnviar(texto);
    if (ok && mounted) setState(_controller.clear);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final abajo = MediaQuery.paddingOf(context).bottom;

    if (widget.cerrado) {
      return Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.superficie2,
            border: Border(top: BorderSide(color: c.separador, width: .5)),
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + abajo),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.lock_outline, color: c.texto2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.textoCerrado,
                  style: TextStyle(fontSize: 15, color: c.texto2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final puedeEnviar = _controller.text.trim().isNotEmpty && !widget.enviando;

    return Container(
      decoration: BoxDecoration(
        color: c.fondo,
        border: Border(top: BorderSide(color: c.separador, width: .5)),
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + abajo),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              maxLength: CompositorMensaje.maxCaracteres,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 17, color: c.texto),
              decoration: InputDecoration(
                hintText: widget.pista,
                hintStyle: TextStyle(color: c.texto3),
                counterText: '',
                filled: true,
                fillColor: c.superficie2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.marca, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Enviar mensaje',
            child: Semantics(
              button: true,
              enabled: puedeEnviar,
              label: widget.enviando ? 'Enviando' : 'Enviar mensaje',
              onTap: puedeEnviar ? _enviar : null,
              excludeSemantics: true,
              child: Presionable(
                onTap: puedeEnviar ? _enviar : null,
                escala: 0.9,
                atenuarInactivo: !widget.enviando,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.marcaSolido,
                    shape: BoxShape.circle,
                  ),
                  child: widget.enviando
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: c.sobreMarca,
                          ),
                        )
                      : Icon(Icons.arrow_upward_rounded, color: c.sobreMarca),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
