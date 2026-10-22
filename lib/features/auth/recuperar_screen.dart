import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../../providers.dart';

class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _enviado = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).recuperarPassword(_email.text);
      if (mounted) setState(() => _enviado = true);
    } on AuthException catch (e) {
      // Por privacidad no revelamos si el correo existe.
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        setState(() => _enviado = true);
      } else {
        showAppSnackBar(context, e.message, error: true);
      }
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
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: _enviado
          ? EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'Revisa tu correo',
              message:
                  'Si ${_email.text.trim()} está registrado, te enviamos un '
                  'enlace para crear una nueva contraseña.',
              actionLabel: 'Volver a iniciar sesión',
              onAction: () => Navigator.of(context).maybePop(),
              color: AppColors.estadoEntregada,
            )
          : Form(
              key: _formKey,
              child: FormPage(
                children: [
                  Text(
                    'Te enviaremos un enlace para crear una contraseña nueva.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Correo',
                    controller: _email,
                    hint: 'tu@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    prefixIcon: Icons.mail_outline,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Enviar enlace',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
