import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/theme/tema.dart';
import '../../../core/widgets/aviso.dart';
import '../../../core/widgets/boton.dart';
import '../../../core/widgets/campo.dart';
import '../../../core/widgets/esqueleto.dart';
import '../../../core/widgets/hoja.dart';
import '../../../core/widgets/presionable.dart';
import '../../../providers.dart';

/// Abre un buscador de países (`/api/ciudades/paises`) en una hoja inferior.
/// Devuelve el país elegido o `null` si se cierra.
Future<String?> showPaisPicker(BuildContext context, {String? actual}) =>
    mostrarHoja<String>(
      context,
      titulo: 'Nacionalidad',
      altoCompleto: true,
      contenido: _PaisPicker(actual: actual),
    );

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
    final paises = ref.watch(paisesProvider);
    final q = _query.text.trim().toLowerCase();
    final texto = _query.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Semantics(
            label: 'Buscar país',
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 17, color: context.c.texto),
              decoration: decoracionCampo(
                context,
                pista: 'Buscar país (en inglés)',
                prefijo: Icon(Icons.search, color: context.c.texto2),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: switch (paises) {
            AsyncData(value: final lista) => _lista(lista, q, texto),
            AsyncError(:final error) => _relleno(
              Aviso(
                error is AppException
                    ? error.message
                    : 'No pudimos cargar la lista de países.',
                tipo: TipoAviso.error,
                accion: Wrap(
                  spacing: 8,
                  children: [
                    Boton(
                      'Reintentar',
                      chico: true,
                      ancho: false,
                      variante: VarianteBoton.secundario,
                      onTap: () => ref.invalidate(paisesProvider),
                    ),
                    if (texto.isNotEmpty)
                      Boton(
                        'Usar "$texto"',
                        chico: true,
                        ancho: false,
                        variante: VarianteBoton.tonal,
                        onTap: () => Navigator.of(context).pop(texto),
                      ),
                  ],
                ),
              ),
            ),
            _ => _relleno(const EsqueletoLista(cantidad: 6, alto: 44)),
          },
        ),
      ],
    );
  }

  Widget _relleno(Widget hijo) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
    child: hijo,
  );

  Widget _lista(List<String> lista, String q, String texto) {
    final filtrados = q.isEmpty
        ? [
            ..._sugeridos.where(lista.contains),
            ...lista.where((p) => !_sugeridos.contains(p)),
          ]
        : lista.where((p) => p.toLowerCase().contains(q)).toList();
    if (filtrados.isEmpty) {
      return _relleno(
        Aviso(
          'No encontramos "$texto" en la lista.',
          accion: texto.isEmpty
              ? null
              : Boton(
                  'Usar "$texto"',
                  chico: true,
                  ancho: false,
                  variante: VarianteBoton.tonal,
                  onTap: () => Navigator.of(context).pop(texto),
                ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 20 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: filtrados.length,
      itemBuilder: (context, i) {
        final pais = filtrados[i];
        return _FilaPais(
          pais: pais,
          seleccionado: pais == widget.actual,
          onTap: () => Navigator.of(context).pop(pais),
        );
      },
    );
  }
}

class _FilaPais extends StatelessWidget {
  const _FilaPais({
    required this.pais,
    required this.seleccionado,
    required this.onTap,
  });

  final String pais;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: seleccionado,
      label: pais,
      onTap: onTap,
      excludeSemantics: true,
      child: Presionable(
        onTap: onTap,
        escala: 0.99,
        child: Container(
          constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.separador)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pais,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: seleccionado ? FontWeight.w600 : null,
                    color: seleccionado ? c.marca : c.texto,
                  ),
                ),
              ),
              if (seleccionado) Icon(Icons.check_rounded, color: c.marca),
            ],
          ),
        ),
      ),
    );
  }
}
