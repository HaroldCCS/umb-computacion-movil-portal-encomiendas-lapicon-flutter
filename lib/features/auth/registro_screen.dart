import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .crearCuenta(_email.text, _password.text);
      // Con la sesión creada, el router lleva a "Completar perfil".
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: FormPage(
            children: [
              Text('Empecemos', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Solo te pedimos lo necesario. Tus datos de contacto los '
                'completas en el siguiente paso.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Correo',
                controller: _email,
                hint: 'tu@correo.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                prefixIcon: Icons.mail_outline,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Contraseña',
                controller: _password,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                prefixIcon: Icons.lock_outline,
                helper: 'Mínimo 6 caracteres.',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              PasswordStrengthBar(value: _password.text),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirmar contraseña',
                controller: _confirm,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.confirmarPassword(() => _password.text),
                prefixIcon: Icons.lock_outline,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Crear cuenta',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de fortaleza de la contraseña (validación positiva).
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = Validators.fortalezaPassword(value);
    if (level == 0) return const SizedBox.shrink();
    const labels = ['', 'Débil', 'Media', 'Fuerte'];
    const colors = [
      Colors.transparent,
      AppColors.estadoCancelada,
      AppColors.estadoTomada,
      AppColors.estadoEntregada,
    ];
    return Semantics(
      label: 'Seguridad de la contraseña: ${labels[level]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= level
                      ? colors[level]
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          const SizedBox(width: AppSpacing.xs),
          Text(
            labels[level],
            style: theme.textTheme.labelMedium?.copyWith(color: colors[level]),
          ),
        ],
      ),
    );
  }
}
