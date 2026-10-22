import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../providers.dart';

/// Abre un buscador de países (`/api/ciudades/paises`) en una hoja inferior.
/// Devuelve el país elegido o `null` si se cierra.
Future<String?> showPaisPicker(BuildContext context, {String? actual}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _PaisPicker(actual: actual),
    ),
  );
}

class _PaisPicker extends ConsumerStatefulWidget {
  const _PaisPicker({this.actual});

  final String? actual;

  @override
  ConsumerState<_PaisPicker> createState() => _PaisPickerState();
}

class _PaisPickerState extends ConsumerState<_PaisPicker> {
  final _query = TextEditingController();

  /// Atajos para Latinoamérica, que es el público principal.
  static const _sugeridos = [
    'Colombia',
    'United States',
    'Mexico',
    'Spain',
    'Peru',
    'Ecuador',
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paises = ref.watch(paisesProvider);
    final q = _query.text.trim().toLowerCase();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Nacionalidad', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar país (en inglés, p. ej. "Colombia", "Spain")',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: paises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorConTexto(
                mensaje: e is AppException
                    ? e.message
                    : 'No pudimos cargar la lista de países.',
                texto: _query.text.trim(),
                onRetry: () => ref.invalidate(paisesProvider),
              ),
              data: (lista) {
                final filtrados = q.isEmpty
                    ? [
                        ..._sugeridos.where(lista.contains),
                        ...lista.where((p) => !_sugeridos.contains(p)),
                      ]
                    : lista.where((p) => p.toLowerCase().contains(q)).toList();
                if (filtrados.isEmpty) {
                  return _UsarTexto(texto: _query.text.trim());
                }
                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final pais = filtrados[i];
                    final seleccionado = pais == widget.actual;
                    return ListTile(
                      title: Text(pais),
                      trailing: seleccionado
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      selected: seleccionado,
                      onTap: () => Navigator.of(context).pop(pais),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsarTexto extends StatelessWidget {
  const _UsarTexto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'No encontramos "$texto" en la lista.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (texto.isNotEmpty)
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(texto),
              child: Text('Usar "$texto"'),
            ),
        ],
      ),
    );
  }
}

class _ErrorConTexto extends StatelessWidget {
  const _ErrorConTexto({
    required this.mensaje,
    required this.texto,
    required this.onRetry,
  });

  final String mensaje;
  final String texto;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
          if (texto.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(texto),
              child: Text('Usar "$texto"'),
            ),
          ],
        ],
      ),
    );
  }
}
