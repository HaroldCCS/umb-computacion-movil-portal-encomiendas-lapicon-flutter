import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../providers.dart';
import '../session/session_controller.dart';

/// Pantalla mientras se revisa la sesión y se carga el perfil. Si falla
/// (sin internet, servidor caído) ofrece reintentar o cerrar sesión.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.status == SessionStatus.error) {
            return SafeArea(
              child: ErrorView(
                message: session.error ?? 'Intenta de nuevo.',
                onRetry: session.recargar,
                secondaryLabel: 'Cerrar sesión',
                onSecondary: session.cerrarSesion,
              ),
            );
          }
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 56),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Cargando tu cuenta',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
