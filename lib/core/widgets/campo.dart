import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tema.dart';

/// Decoración común de los campos: relleno `superficie2`, sin borde en
/// reposo, borde `marca` con foco y `peligro` con error.
InputDecoration decoracionCampo(
  BuildContext context, {
  String? pista,
  String? ayuda,
  Widget? prefijo,
  Widget? sufijo,
  String? prefijoTexto,
  bool valido = false,
}) {
  final c = context.c;
  OutlineInputBorder borde(Color color, [double ancho = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.radioCampo),
        borderSide: BorderSide(color: color, width: ancho),
      );
  return InputDecoration(
    hintText: pista,
    hintStyle: TextStyle(color: c.texto3),
    helperText: ayuda,
    helperMaxLines: 3,
    helperStyle: TextStyle(fontSize: 13, color: c.texto2),
    errorMaxLines: 3,
    errorStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: c.peligro,
    ),
    filled: true,
    fillColor: c.superficie2,
    prefixIcon: prefijo,
    prefixText: prefijoTexto,
    suffixIcon: sufijo,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: borde(Colors.transparent),
    enabledBorder: borde(valido ? c.exito : Colors.transparent),
    focusedBorder: borde(c.marca, 2),
    errorBorder: borde(c.peligro),
    focusedErrorBorder: borde(c.peligro, 2),
    disabledBorder: borde(Colors.transparent),
  );
}

/// Etiqueta de campo: arriba, 13/500, `texto2`. Nunca placeholder como
/// etiqueta (docs/07 §7.1).
class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.c.texto2,
      ),
    ),
  );
}

/// Campo de texto del sistema v2 (mismo comportamiento que `AppTextField`):
/// - Etiqueta visible **encima** del campo.
/// - Valida al **salir** del campo, no mientras se escribe por primera vez.
/// - Una vez mostrado un error, re-valida en cada pulsación para quitarlo
///   apenas se corrige.
/// - Validación positiva: check verde cuando el valor es correcto.
class Campo extends StatefulWidget {
  const Campo({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.validador,
    this.pista,
    this.ayuda,
    this.teclado,
    this.accionTeclado = TextInputAction.next,
    this.autofill,
    this.contrasena = false,
    this.capitalizacion = TextCapitalization.none,
    this.formateadores,
    this.alEnviar,
    this.alCambiar,
    this.icono,
    this.habilitado = true,
    this.soloLectura = false,
    this.alTocar,
    this.sufijo,
    this.maxLength,
    this.lineas = 1,
    this.checkValido = true,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final String? Function(String?)? validador;
  final String? pista;
  final String? ayuda;
  final TextInputType? teclado;
  final TextInputAction accionTeclado;
  final Iterable<String>? autofill;

  /// Oculta el texto y agrega el ojo para verlo.
  final bool contrasena;
  final TextCapitalization capitalizacion;
  final List<TextInputFormatter>? formateadores;
  final ValueChanged<String>? alEnviar;
  final ValueChanged<String>? alCambiar;
  final IconData? icono;
  final bool habilitado;
  final bool soloLectura;
  final VoidCallback? alTocar;
  final Widget? sufijo;
  final int? maxLength;
  final int lineas;
  final bool checkValido;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  final _clave = GlobalKey<FormFieldState<String>>();
  final _foco = FocusNode();
  bool _tocado = false;
  bool _oculto = true;

  @override
  void initState() {
    super.initState();
    _foco.addListener(_alCambiarFoco);
  }

  @override
  void dispose() {
    _foco
      ..removeListener(_alCambiarFoco)
      ..dispose();
    super.dispose();
  }

  void _alCambiarFoco() {
    if (!_foco.hasFocus && widget.controlador.text.isNotEmpty) {
      setState(() => _tocado = true);
      _clave.currentState?.validate();
    }
  }

  void _alCambiar(String valor) {
    final estado = _clave.currentState;
    if (_tocado || (estado?.hasError ?? false)) {
      estado?.validate();
      setState(() {}); // actualiza el check de validación positiva
    }
    widget.alCambiar?.call(valor);
  }

  bool get _valido =>
      _tocado &&
      widget.controlador.text.isNotEmpty &&
      (widget.validador?.call(widget.controlador.text) == null);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final valido = widget.checkValido && !widget.contrasena && _valido;

    Widget? sufijo = widget.sufijo;
    if (widget.contrasena) {
      sufijo = IconButton(
        tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(
          _oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: c.texto2,
        ),
        onPressed: () => setState(() => _oculto = !_oculto),
      );
    } else if (sufijo == null && valido) {
      sufijo = Icon(
        Icons.check_circle,
        color: c.exito,
        semanticLabel: 'Campo válido',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EtiquetaCampo(widget.etiqueta),
        TextFormField(
          key: _clave,
          controller: widget.controlador,
          focusNode: _foco,
          validator: widget.validador,
          autovalidateMode: AutovalidateMode.disabled,
          keyboardType: widget.teclado,
          textInputAction: widget.accionTeclado,
          autofillHints: widget.autofill,
          obscureText: widget.contrasena && _oculto,
          enableSuggestions: !widget.contrasena,
          autocorrect: !widget.contrasena,
          textCapitalization: widget.capitalizacion,
          inputFormatters: widget.formateadores,
          onChanged: _alCambiar,
          onFieldSubmitted: widget.alEnviar,
          enabled: widget.habilitado,
          readOnly: widget.soloLectura,
          onTap: widget.alTocar,
          maxLength: widget.maxLength,
          minLines: widget.lineas,
          maxLines: widget.contrasena ? 1 : widget.lineas,
          style: TextStyle(fontSize: 17, color: c.texto),
          decoration: decoracionCampo(
            context,
            pista: widget.pista,
            ayuda: widget.ayuda,
            prefijo: widget.icono == null
                ? null
                : Icon(widget.icono, color: c.texto2),
            sufijo: sufijo,
            valido: valido,
          ),
        ),
      ],
    );
  }
}

/// Contraseña con ojo para verla y aviso que se pone verde al cumplir el
/// mínimo ("✓ Mínimo 6 caracteres.").
class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    required this.controlador,
    this.etiqueta = 'Contraseña',
    this.minimo,
    this.nueva = false,
    this.validador,
    this.accionTeclado = TextInputAction.next,
    this.alEnviar,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final int? minimo;

  /// `true` en registro: sugiere `newPassword` al gestor de contraseñas.
  final bool nueva;
  final String? Function(String?)? validador;
  final TextInputAction accionTeclado;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_refrescar);
  }

  @override
  void didUpdateWidget(CampoContrasena viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.controlador != widget.controlador) {
      viejo.controlador.removeListener(_refrescar);
      widget.controlador.addListener(_refrescar);
    }
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_refrescar);
    super.dispose();
  }

  void _refrescar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final minimo = widget.minimo;
    final cumple = minimo != null && widget.controlador.text.length >= minimo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Campo(
          etiqueta: widget.etiqueta,
          controlador: widget.controlador,
          contrasena: true,
          validador: widget.validador,
          accionTeclado: widget.accionTeclado,
          alEnviar: widget.alEnviar,
          autofill: [
            widget.nueva ? AutofillHints.newPassword : AutofillHints.password,
          ],
        ),
        if (minimo != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              '${cumple ? '✓ ' : ''}Mínimo $minimo caracteres.',
              style: TextStyle(
                fontSize: 13,
                color: cumple ? c.exito : c.texto2,
                fontWeight: cumple ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

/// Valor grande centrado ("¿Cuánto pagas?") con separador de miles y la
/// moneda delante. El número se lee con [CampoMonto.valorDe].
class CampoMonto extends StatelessWidget {
  const CampoMonto({
    super.key,
    required this.controlador,
    required this.moneda,
    this.etiqueta = '¿Cuánto?',
    this.validador,
  });

  final TextEditingController controlador;
  final String moneda;
  final String etiqueta;
  final String? Function(String?)? validador;

  /// `'1.234.567'` → `1234567` (0 si está vacío).
  static int valorDe(TextEditingController controlador) =>
      int.tryParse(controlador.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final estilo = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: c.texto,
      fontFeatures: cifras,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: c.superficie2,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: Column(
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.texto2,
            ),
          ),
          TextFormField(
            controller: controlador,
            validator: validador,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const FormateadorMiles(),
            ],
            style: estilo,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: estilo.copyWith(color: c.texto3),
              prefixText: '${moneda.toUpperCase()} ',
              prefixStyle: estilo.copyWith(fontSize: 22, color: c.texto2),
              errorStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.peligro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Agrupa los dígitos de a tres con punto: `1234567` → `1.234.567`.
class FormateadorMiles extends TextInputFormatter {
  const FormateadorMiles();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue viejo,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll('.', '');
    if (digitos.isEmpty) return TextEditingValue.empty;
    final b = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) b.write('.');
      b.write(digitos[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
