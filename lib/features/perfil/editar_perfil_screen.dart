import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/pantalla.dart';
import '../../core/widgets/toast.dart';
import '../../providers.dart';
import 'widgets/perfil_form.dart';

/// Edición del perfil propio → `PUT /api/users/:uid`.
class EditarPerfilScreen extends ConsumerWidget {
  const EditarPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final perfil = session.perfil;

    return Pantalla(
      titulo: 'Editar perfil',
      textoAtras: 'Perfil',
      hijos: perfil == null
          ? const []
          : [
              PerfilForm(
                uid: perfil.uid,
                email: session.email,
                inicial: perfil,
                submitLabel: 'Guardar cambios',
                // Si falla, PerfilForm muestra el error junto al botón.
                onSubmit: (datos) async {
                  await session.actualizarPerfil(datos);
                  if (!context.mounted) return;
                  mostrarToast(context, 'Perfil actualizado');
                  Navigator.of(context).maybePop();
                },
              ),
            ],
    );
  }
}
