import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

/// Campo de texto del sistema de diseño (docs/07 §7.1 y §7.5):
/// - Etiqueta visible **encima** del campo (nunca solo placeholder).
/// - Valida al **salir** del campo, no mientras se escribe por primera vez.
/// - Una vez mostrado un error, se re-valida en cada pulsación para quitarlo
///   apenas se corrige.
/// - Validación positiva: check verde cuando el valor es correcto.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.hint,
    this.helper,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.maxLength,
    this.showValidCheck = true,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final int? maxLength;
  final bool showValidCheck;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();
  bool _touched = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      setState(() => _touched = true);
      _fieldKey.currentState?.validate();
    }
  }

  void _onChanged(String value) {
    final state = _fieldKey.currentState;
    if (_touched || (state?.hasError ?? false)) {
      state?.validate();
      setState(() {}); // actualiza el check de validación positiva
    }
    widget.onChanged?.call(value);
  }

  bool get _isValid =>
      _touched &&
      widget.controller.text.isNotEmpty &&
      (widget.validator?.call(widget.controller.text) == null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    Widget? suffix = widget.suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        tooltip: _obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    } else if (suffix == null && widget.showValidCheck && _isValid) {
      suffix = const Icon(
        Icons.check_circle,
        color: AppColors.estadoEntregada,
        semanticLabel: 'Campo válido',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
          child: Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        TextFormField(
          key: _fieldKey,
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.disabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          obscureText: widget.isPassword && _obscured,
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          onChanged: _onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          maxLength: widget.maxLength,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 2,
            errorMaxLines: 2,
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: border(scheme.outlineVariant),
            enabledBorder: border(
              _isValid ? AppColors.estadoEntregada : scheme.outlineVariant,
            ),
            focusedBorder: border(scheme.primary, 2),
            errorBorder: border(scheme.error),
            focusedErrorBorder: border(scheme.error, 2),
            disabledBorder: border(
              scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
