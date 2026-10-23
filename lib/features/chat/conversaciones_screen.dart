import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../providers.dart';
import 'chat_providers.dart';
import 'chat_service.dart';
import 'models/conversacion.dart';

/// Pestaña "Chats": mis conversaciones en tiempo real (Práctica 5).
class ConversacionesScreen extends ConsumerWidget {
  const ConversacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miUid = ref.watch(sessionProvider).user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: miUid == null
          ? const SizedBox.shrink()
          : ref
                .watch(conversacionesProvider(miUid))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(
                    message: mensajeErrorChat(e),
                    onRetry: () =>
                        ref.invalidate(conversacionesProvider(miUid)),
                  ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const EmptyState(
                        icon: Icons.forum_outlined,
                        title: 'Aún no tienes conversaciones',
                        message:
                            'Cuando una encomienda sea tomada podrás '
                            'coordinar la entrega por aquí.',
                      );
                    }
                    return ListView.separated(
                      // Relleno inferior para la barra flotante.
                      padding: EdgeInsets.only(
                        top: AppSpacing.xs,
                        bottom: Medidas.bajoBarra(context),
                      ),
                      itemCount: lista.length,
                      separatorBuilder: (context, i) => const Divider(
                        height: 1,
                        indent: AppSpacing.md + 48 + AppSpacing.md,
                      ),
                      itemBuilder: (context, i) => _ConversacionTile(
                        conversacion: lista[i],
                        miUid: miUid,
                      ),
                    );
                  },
                ),
    );
  }
}

class _ConversacionTile extends StatelessWidget {
  const _ConversacionTile({required this.conversacion, required this.miUid});

  final Conversacion conversacion;
  final String miUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otroUid = conversacion.otroUid(miUid);
    final nombre = conversacion.nombreDe(otroUid);
    final ultimo = conversacion.ultimoMensaje ?? 'Sin mensajes todavía';
    final prefijo = conversacion.ultimoEmisorUid == miUid ? 'Tú: ' : '';
    final cuando = Fmt.relativo(conversacion.actualizadoEn);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          inicialesDe(nombre),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (conversacion.ruta != null)
            Text(
              conversacion.ruta!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            '$prefijo$ultimo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: cuando.isEmpty
          ? null
          : Text(cuando, style: theme.textTheme.labelSmall),
      onTap: otroUid == null
          ? null
          : () => context.push(
              Routes.chat,
              extra: ChatArgs(otroUid: otroUid, otroNombre: nombre),
            ),
    );
  }
}
