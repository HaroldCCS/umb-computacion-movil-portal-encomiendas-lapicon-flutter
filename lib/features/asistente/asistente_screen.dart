import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import 'asistente_controller.dart';

/// Sugerencias iniciales según el rol.
List<String> sugerenciasAsistente(Rol? rol) => switch (rol) {
  Rol.viajero => const [
    '¿Cómo registro mi vuelo?',
    '¿Qué no puedo llevar en mi maleta?',
    '¿Cómo tomo una encomienda?',
  ],
  _ => const [
    '¿Cómo publico una encomienda?',
    'Quiero enviar algo de Bogota a Miami',
    '¿Cómo elijo un viajero confiable?',
  ],
};

/// Chat con el asistente de IA (`POST /api/chatbot`).
class AsistenteScreen extends ConsumerStatefulWidget {
  const AsistenteScreen({super.key});

  @override
  ConsumerState<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends ConsumerState<AsistenteScreen> {
  final _texto = TextEditingController();

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar([String? sugerencia]) {
    final texto = sugerencia ?? _texto.text;
    if (texto.trim().isEmpty) return;
    ref.read(asistenteProvider.notifier).enviar(texto);
    if (sugerencia == null) _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estado = ref.watch(asistenteProvider);
    final rol = ref.watch(sessionProvider).rol;
    // La lista va invertida para que lo más reciente quede abajo.
    final items = <Widget>[
      if (estado.escribiendo) const _Escribiendo(),
      for (final m in estado.mensajes.reversed)
        _Burbuja(
          mensaje: m,
          onReintentar: m.error
              ? () => ref.read(asistenteProvider.notifier).reintentar(m)
              : null,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh),
            onPressed: estado.esNueva
                ? null
                : () => ref.read(asistenteProvider.notifier).reiniciar(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: items,
              ),
            ),
            if (estado.esNueva && !estado.escribiendo)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in sugerenciasAsistente(rol))
                      ActionChip(label: Text(s), onPressed: () => _enviar(s)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Respuestas generadas por IA; verifica la información '
                'importante.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _texto,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta…',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: _texto.text.trim().isEmpty || estado.escribiendo
                        ? null
                        : _enviar,
                    icon: const Icon(Icons.send_rounded),
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

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, this.onReintentar});

  final MensajeAsistente mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final propio = mensaje.autor == AutorMensaje.usuario;
    final fondo = mensaje.error
        ? scheme.errorContainer
        : (propio ? scheme.primary : scheme.surfaceContainerLowest);
    final texto = mensaje.error
        ? scheme.onErrorContainer
        : (propio ? scheme.onPrimary : scheme.onSurface);

    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Semantics(
          label: propio ? 'Tú' : 'Asistente',
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(propio ? 18 : 4),
                bottomRight: Radius.circular(propio ? 4 : 18),
              ),
              border: propio || mensaje.error
                  ? null
                  : Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensaje.texto,
                  style: theme.textTheme.bodyLarge?.copyWith(color: texto),
                ),
                if (onReintentar != null)
                  TextButton.icon(
                    onPressed: onReintentar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: TextButton.styleFrom(foregroundColor: texto),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: 'El asistente está escribiendo',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Escribiendo…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
