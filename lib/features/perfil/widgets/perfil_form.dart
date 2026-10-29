import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/aviso.dart';
import '../../../core/widgets/boton.dart';
import '../../../core/widgets/campo.dart';
import '../../../core/widgets/hoja.dart';
import '../../../data/models/viaje.dart';
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
    _nacimientoTexto.dispose();
    super.dispose();
  }

  Future<void> _elegirPais() async {
    final pais = await showPaisPicker(context, actual: _nacionalidad.text);
    if (pais != null && mounted) setState(() => _nacionalidad.text = pais);
  }

  late String? _nacimiento = widget.inicial?.fechaNacimiento;
  late final _nacimientoTexto = TextEditingController(
    text: _nacimiento == null ? '' : Fmt.fecha(DateTime.parse(_nacimiento!)),
  );

  /// Rueda de iOS en una hoja, como la fecha del vuelo.
  Future<void> _elegirNacimiento() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await mostrarHoja<DateTime>(
      context,
      titulo: 'Fecha de nacimiento',
      contenido: _SelectorNacimiento(
        inicial: _nacimiento == null
            ? DateTime(hoy.year - 25, hoy.month, hoy.day)
            : DateTime.parse(_nacimiento!),
        maxima: hoy,
      ),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _nacimiento = Viaje.fechaIso(elegida);
      _nacimientoTexto.text = Fmt.fecha(elegida);
    });
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
          fechaNacimiento: _nacimiento,
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
            const SizedBox(height: 16),
            Campo(
              etiqueta: 'Fecha de nacimiento (opcional)',
              controlador: _nacimientoTexto,
              pista: 'Elige la fecha',
              ayuda: 'Solo para confirmar que eres mayor de edad.',
              soloLectura: true,
              alTocar: _elegirNacimiento,
              icono: Icons.cake_outlined,
              checkValido: false,
              sufijo: const Icon(Icons.expand_more),
              validador: (_) => Validators.fechaNacimiento(_nacimiento),
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

/// Contenido de la hoja de fecha de nacimiento.
class _SelectorNacimiento extends StatefulWidget {
  const _SelectorNacimiento({required this.inicial, required this.maxima});

  final DateTime inicial;
  final DateTime maxima;

  @override
  State<_SelectorNacimiento> createState() => _SelectorNacimientoState();
}

class _SelectorNacimientoState extends State<_SelectorNacimiento> {
  late DateTime _fecha = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: widget.inicial,
            minimumDate: DateTime(widget.maxima.year - 120),
            maximumDate: widget.maxima,
            onDateTimeChanged: (f) => _fecha = DateUtils.dateOnly(f),
          ),
        ),
        const SizedBox(height: 16),
        Boton(
          'Elegir esta fecha',
          onTap: () => Navigator.of(context).pop(_fecha),
        ),
      ],
    );
  }
}
