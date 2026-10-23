import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/fila_opcion.dart';
import '../../core/widgets/hoja.dart';
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
    return Campo(
      etiqueta: label,
      controlador: controller,
      pista: hint,
      soloLectura: true,
      icono: icon,
      checkValido: false,
      sufijo: const Icon(Icons.expand_more),
      validador: (v) => Validators.requerido(v, label),
      alTocar: () async {
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
}) => mostrarHoja<String>(
  context,
  titulo: titulo,
  altoCompleto: true,
  contenido: _CiudadPicker(actual: actual),
);

class _CiudadPicker extends ConsumerStatefulWidget {
  const _CiudadPicker({this.actual});

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
    final ciudades = ref.watch(ciudadesProvider);
    final q = _norm(_query.text);

    Widget relleno(Widget hijo) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: hijo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Semantics(
            label: 'Buscar ciudad',
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 17, color: context.c.texto),
              decoration: decoracionCampo(
                context,
                pista: 'Buscar ciudad (p. ej. "Bogota")',
                prefijo: Icon(Icons.search, color: context.c.texto2),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: switch (ciudades) {
            AsyncData(value: final lista) => () {
              final filtradas = q.isEmpty
                  ? lista
                  : lista.where((c) => _norm(c).contains(q)).toList();
              if (filtradas.isEmpty) {
                return relleno(
                  Aviso(
                    'No encontramos "${_query.text.trim()}". Prueba sin '
                    'tildes o con el nombre en inglés.',
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.only(
                  bottom: 20 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: filtradas.length,
                itemBuilder: (context, i) => FilaOpcion(
                  texto: filtradas[i],
                  icono: Icons.location_city_outlined,
                  seleccionada: filtradas[i] == widget.actual,
                  onTap: () => Navigator.of(context).pop(filtradas[i]),
                ),
              );
            }(),
            AsyncError(:final error) => relleno(
              Aviso(
                error is AppException
                    ? error.message
                    : 'No pudimos cargar las ciudades.',
                tipo: TipoAviso.error,
                accion: Boton(
                  'Reintentar',
                  chico: true,
                  ancho: false,
                  variante: VarianteBoton.secundario,
                  onTap: () => ref.invalidate(ciudadesProvider),
                ),
              ),
            ),
            _ => relleno(const EsqueletoLista(cantidad: 6, alto: 44)),
          },
        ),
      ],
    );
  }
}
