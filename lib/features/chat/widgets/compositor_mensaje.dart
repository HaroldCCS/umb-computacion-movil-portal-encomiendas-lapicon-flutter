import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Barra inferior para escribir. Si [cerrado], se muestra deshabilitada con
/// la explicación (reto 4: bloquear el envío cuando el chat se cierra).
class CompositorMensaje extends StatefulWidget {
  const CompositorMensaje({
    super.key,
    required this.onEnviar,
    this.cerrado = false,
    this.enviando = false,
  });

  /// Devuelve `true` si el mensaje se envió (para limpiar el campo).
  final Future<bool> Function(String texto) onEnviar;
  final bool cerrado;
  final bool enviando;

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.cerrado) {
      return Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Este chat se cerró porque la entrega terminó.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final puedeEnviar = _controller.text.trim().isNotEmpty && !widget.enviando;

    return Material(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
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
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje',
                    counterText: '',
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox.square(
                dimension: 48,
                child: widget.enviando
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : IconButton.filled(
                        tooltip: 'Enviar mensaje',
                        onPressed: puedeEnviar ? _enviar : null,
                        icon: const Icon(Icons.send_rounded),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
