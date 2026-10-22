import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers.dart';

/// Campo para elegir una ciudad de `/api/ciudades/ciudades`. Se elige de la
/// lista (no texto libre) para que el nombre coincida exactamente con el que
/// usan los filtros del backend (p. ej. "Bogota", sin tilde).
class CiudadField extends StatelessWidget {
  const CiudadField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = 'Elige una ciudad',
    this.onChanged,
    this.icon = Icons.location_on_outlined,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hint: hint,
      readOnly: true,
      prefixIcon: icon,
      showValidCheck: false,
      suffix: const Icon(Icons.expand_more),
      validator: (v) => Validators.requerido(v, label),
      onTap: () async {
        final ciudad = await showCiudadPicker(
          context,
          titulo: label,
          actual: controller.text,
        );
        if (ciudad != null) {
          controller.text = ciudad;
          onChanged?.call(ciudad);
        }
      },
    );
  }
}

/// Buscador de ciudades en hoja inferior. Devuelve la ciudad o `null`.
Future<String?> showCiudadPicker(
  BuildContext context, {
  required String titulo,
  String? actual,
}) {
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
      child: _CiudadPicker(titulo: titulo, actual: actual),
    ),
  );
}

class _CiudadPicker extends ConsumerStatefulWidget {
  const _CiudadPicker({required this.titulo, this.actual});

  final String titulo;
  final String? actual;

  @override
  ConsumerState<_CiudadPicker> createState() => _CiudadPickerState();
}

class _CiudadPickerState extends ConsumerState<_CiudadPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Compara sin tildes ni mayúsculas ("bogotá" encuentra "Bogota").
  static String _norm(String s) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? to[i] : ch);
    }
    return buffer.toString().toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ciudades = ref.watch(ciudadesProvider);
    final q = _norm(_query.text);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(widget.titulo, style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar ciudad (p. ej. "Bogota", "Miami")',
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
            child: ciudades.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      e is AppException
                          ? e.message
                          : 'No pudimos cargar las ciudades.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(ciudadesProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (lista) {
                final filtradas = q.isEmpty
                    ? lista
                    : lista.where((c) => _norm(c).contains(q)).toList();
                if (filtradas.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No encontramos "${_query.text.trim()}". Prueba sin '
                      'tildes o con el nombre en inglés.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (context, i) {
                    final ciudad = filtradas[i];
                    final sel = ciudad == widget.actual;
                    return ListTile(
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(ciudad),
                      selected: sel,
                      trailing: sel
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(ciudad),
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
