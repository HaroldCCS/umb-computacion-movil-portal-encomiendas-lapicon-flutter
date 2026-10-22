import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/route_ticket.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .iniciarSesion(_email.text, _password.text);
      // El router redirige solo cuando cambia la sesión.
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
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: FormPage(
            children: [
              const SizedBox(height: AppSpacing.md),
              const Align(alignment: Alignment.centerLeft, child: BrandMark()),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tu paquete viaja con alguien que ya va para allá.',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              const ExcludeSemantics(
                child: RouteTicket(
                  origen: 'Bogotá',
                  destino: 'Miami',
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                prefixIcon: Icons.lock_outline,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : () => context.push('/recuperar'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Iniciar sesión',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => context.push('/registro'),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
