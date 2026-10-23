import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/aviso.dart';
import '../../../core/widgets/boton.dart';
import '../../../core/widgets/campo.dart';
import '../../../data/models/usuario.dart';
import 'pais_picker.dart';

/// Formulario de perfil compartido por "Completar perfil" y "Editar perfil".
class PerfilForm extends StatefulWidget {
  const PerfilForm({
    super.key,
    required this.uid,
    required this.submitLabel,
    required this.onSubmit,
    this.inicial,
    this.email,
  });

  final String uid;
  final String submitLabel;
  final Usuario? inicial;
  final String? email;

  /// Debe lanzar [AppException] si falla: el formulario muestra el error
  /// junto al botón y maneja la carga.
  final Future<void> Function(Usuario datos) onSubmit;

  @override
  State<PerfilForm> createState() => _PerfilFormState();
}

class _PerfilFormState extends State<PerfilForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.inicial?.nombre);
  late final _apellido = TextEditingController(text: widget.inicial?.apellido);
  late final _telefono = TextEditingController(text: widget.inicial?.telefono);
  late final _nacionalidad = TextEditingController(
    text: (widget.inicial?.nacionalidad.isNotEmpty ?? false)
        ? widget.inicial!.nacionalidad
        : 'Colombia',
  );
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _nacionalidad.dispose();
    super.dispose();
  }

  Future<void> _elegirPais() async {
    final pais = await showPaisPicker(context, actual: _nacionalidad.text);
    if (pais != null && mounted) setState(() => _nacionalidad.text = pais);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        Usuario(
          uid: widget.uid,
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
          telefono: _telefono.text.replaceAll(RegExp(r'\s'), ''),
          nacionalidad: _nacionalidad.text.trim(),
          email: widget.email,
          rol: widget.inicial?.rol,
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Campo(
              etiqueta: 'Nombre',
              controlador: _nombre,
              pista: 'Laura',
              capitalizacion: TextCapitalization.words,
              autofill: const [AutofillHints.givenName],
              validador: (v) => Validators.nombre(v, 'El nombre'),
            ),
            const SizedBox(height: 16),
            Campo(
              etiqueta: 'Apellido',
              controlador: _apellido,
              pista: 'Gómez',
              capitalizacion: TextCapitalization.words,
              autofill: const [AutofillHints.familyName],
              validador: (v) => Validators.nombre(v, 'El apellido'),
            ),
            const SizedBox(height: 16),
            Campo(
              etiqueta: 'Teléfono',
              controlador: _telefono,
              pista: '300 000 0000',
              ayuda: 'Lo verá la persona con la que coordines una entrega.',
              teclado: TextInputType.phone,
              autofill: const [AutofillHints.telephoneNumber],
              formateadores: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s+()-]')),
              ],
              validador: Validators.telefono,
              icono: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            Campo(
              etiqueta: 'Nacionalidad',
              controlador: _nacionalidad,
              soloLectura: true,
              alTocar: _elegirPais,
              accionTeclado: TextInputAction.done,
              validador: (v) => Validators.requerido(v, 'La nacionalidad'),
              icono: Icons.public,
              checkValido: false,
              sufijo: const Icon(Icons.expand_more),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Aviso(_error!, tipo: TipoAviso.error),
              const SizedBox(height: 12),
            ],
            Boton(
              widget.submitLabel,
              textoCargando: 'Guardando…',
              cargando: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
