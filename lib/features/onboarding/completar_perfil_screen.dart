import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../providers.dart';
import '../perfil/widgets/perfil_form.dart';

/// Paso 1 de 2 del registro: datos de contacto → `POST /api/users/register`.
class CompletarPerfilScreen extends ConsumerWidget {
  const CompletarPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tu perfil'),
        actions: [
          TextButton(
            onPressed: session.cerrarSesion,
            child: const Text('Salir'),
          ),
        ],
      ),
      body: user == null
          ? const SizedBox.shrink()
          : FormPage(
              children: [
                const StepIndicator(step: 1, total: 2),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Cuéntanos quién eres',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Así te reconocerán remitentes y viajeros.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PerfilForm(
                  uid: user.uid,
                  email: user.email,
                  inicial: session.perfil,
                  submitLabel: 'Continuar',
                  onSubmit: (datos) async {
                    try {
                      await session.registrarPerfil(datos);
                    } on AppException catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(context, e.message, error: true);
                      }
                    }
                  },
                ),
              ],
            ),
    );
  }
}
