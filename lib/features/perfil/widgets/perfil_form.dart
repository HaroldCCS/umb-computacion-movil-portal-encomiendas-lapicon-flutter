import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
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

  /// Debe lanzar una excepción si falla; el formulario maneja la carga.
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
            AppTextField(
              label: 'Nombre',
              controller: _nombre,
              hint: 'Laura',
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              validator: (v) => Validators.nombre(v, 'El nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Apellido',
              controller: _apellido,
              hint: 'Gómez',
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              validator: (v) => Validators.nombre(v, 'El apellido'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Teléfono',
              controller: _telefono,
              hint: '300 000 0000',
              helper: 'Lo verá la persona con la que coordines una entrega.',
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s+()-]')),
              ],
              validator: Validators.telefono,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nacionalidad',
              controller: _nacionalidad,
              readOnly: true,
              onTap: _elegirPais,
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.requerido(v, 'La nacionalidad'),
              prefixIcon: Icons.public,
              showValidCheck: false,
              suffix: const Icon(Icons.expand_more),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: widget.submitLabel,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
