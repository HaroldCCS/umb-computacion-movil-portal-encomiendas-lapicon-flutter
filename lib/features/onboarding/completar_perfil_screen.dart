import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/brand.dart';
import '../../core/widgets/pantalla.dart';
import '../../providers.dart';
import '../perfil/widgets/perfil_form.dart';

/// Paso 1 de 2 del registro: datos de contacto → `POST /api/users/register`.
class CompletarPerfilScreen extends ConsumerWidget {
  const CompletarPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Pantalla(
      titulo: 'Tu perfil',
      subtitulo: 'Así te reconocerán remitentes y viajeros.',
      accion: TextButton(
        onPressed: session.cerrarSesion,
        child: const Text('Salir'),
      ),
      hijos: user == null
          ? const []
          : [
              const StepIndicator(step: 1, total: 2),
              // Si falla, PerfilForm muestra el error junto al botón.
              PerfilForm(
                uid: user.uid,
                email: user.email,
                inicial: session.perfil,
                submitLabel: 'Continuar',
                onSubmit: session.registrarPerfil,
              ),
            ],
    );
  }
}
