import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../providers.dart';
import 'widgets/perfil_form.dart';

/// Edición del perfil propio → `PUT /api/users/:uid`.
class EditarPerfilScreen extends ConsumerWidget {
  const EditarPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final perfil = session.perfil;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: perfil == null
          ? const SizedBox.shrink()
          : FormPage(
              children: [
                PerfilForm(
                  uid: perfil.uid,
                  email: session.email,
                  inicial: perfil,
                  submitLabel: 'Guardar cambios',
                  onSubmit: (datos) async {
                    try {
                      await session.actualizarPerfil(datos);
                      if (!context.mounted) return;
                      showAppSnackBar(context, 'Perfil actualizado');
                      Navigator.of(context).maybePop();
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
