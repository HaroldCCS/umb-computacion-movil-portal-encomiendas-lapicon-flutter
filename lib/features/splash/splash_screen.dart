import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tema.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/brand.dart';
import '../../providers.dart';
import '../session/session_controller.dart';

/// Pantalla mientras se revisa la sesión y se carga el perfil. Si falla
/// (sin internet, servidor caído) ofrece reintentar o cerrar sesión.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final session = ref.watch(sessionProvider);
    return Scaffold(
      backgroundColor: c.fondo,
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.status == SessionStatus.error) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Medidas.margen),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Medidas.anchoMaximo,
                    ),
                    child: ErrorCarga(
                      mensaje: session.error ?? 'Intenta de nuevo.',
                      alReintentar: session.recargar,
                      textoSecundario: 'Cerrar sesión',
                      alSecundario: session.cerrarSesion,
                    ),
                  ),
                ),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 56),
                const SizedBox(height: 32),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      color: c.marca,
                      backgroundColor: c.superficie2,
                      semanticsLabel: 'Cargando tu cuenta',
                    ),
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
