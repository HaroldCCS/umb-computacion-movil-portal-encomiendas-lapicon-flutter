import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/estado.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers.dart';
import 'chat_providers.dart';
import 'chat_service.dart';
import 'models/conversacion.dart';
import 'models/mensaje_chat.dart';
import 'widgets/burbuja_mensaje.dart';
import 'widgets/compositor_mensaje.dart';

/// Conversación remitente–viajero en tiempo real (Práctica 5).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _enviando = false;

  /// Se marca al re-consultar el estado justo antes de enviar.
  bool _cerradoAlEnviar = false;

  String get _nombreOtro {
    final n = widget.args.otroNombre?.trim() ?? '';
    return n.isEmpty ? 'Chat' : n;
  }

  Future<bool> _enviar(String miUid, String chatId, String texto) async {
    setState(() => _enviando = true);
    try {
      // Reto 4: verificar que el chat siga abierto antes de cada envío.
      try {
        final estado = await ref.read(chatRepositoryProvider).estado(chatId);
        if (estado == EstadoChat.cerrado) {
          if (mounted) {
            setState(() => _cerradoAlEnviar = true);
            showAppSnackBar(context, 'Este chat ya se cerró.', error: true);
          }
          return false;
        }
      } on NetworkException catch (e) {
        if (mounted) showAppSnackBar(context, e.message, error: true);
        return false;
      } on AppException {
        // Si el backend no reconoce el chat (p. ej. aún no existe), se
        // permite enviar: el backend lo cierra al terminar la entrega.
      }

      final session = ref.read(sessionProvider);
      final e = widget.args.encomienda;
      final escritura = ref
          .read(chatServiceProvider)
          .enviar(
            chatId: chatId,
            emisorUid: miUid,
            receptorUid: widget.args.otroUid,
            texto: texto,
            nombreEmisor: session.perfil?.nombreCompleto,
            nombreReceptor: widget.args.otroNombre,
            encomiendaId: e?.id,
            ruta: e == null ? null : '${e.ciudadOrigen} → ${e.ciudadDestino}',
          );
      try {
        // Sin conexión Firestore deja el mensaje en cola y lo envía después:
        // no se bloquea la pantalla esperando al servidor.
        await escritura.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        escritura.ignore();
      }
      return true;
    } on Object catch (error) {
      if (mounted) {
        showAppSnackBar(context, mensajeErrorChat(error), error: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final miUid = ref.watch(sessionProvider).user?.uid;

    if (miUid == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final chatId = ChatRepository.chatId(miUid, widget.args.otroUid);
    final mensajes = ref.watch(mensajesChatProvider(chatId));
    final estado = ref.watch(estadoChatProvider(chatId));
    final cerrado =
        _cerradoAlEnviar ||
        (estado.hasValue && estado.value == EstadoChat.cerrado);
    final encomienda = widget.args.encomienda;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                inicialesDe(_nombreOtro),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreOtro,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cerrado ? 'Chat cerrado' : 'Coordinen la entrega aquí',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (encomienda != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: RouteTicket(
                origen: encomienda.ciudadOrigen,
                destino: encomienda.ciudadDestino,
                compact: true,
                trailing: StatusChip.encomienda(encomienda.estado),
              ),
            ),
          Expanded(
            child: mensajes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: mensajeErrorChat(e),
                onRetry: () => ref.invalidate(mensajesChatProvider(chatId)),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Saluda a $_nombreOtro',
                    message:
                        'Acuerden dónde y cuándo entregar el paquete. '
                        'Revisen juntos el contenido antes del viaje.',
                  );
                }
                final items = agruparPorDia(lista).reversed.toList();
                // Lista invertida: el mensaje más reciente queda abajo y la
                // vista se mantiene al final cuando llegan mensajes nuevos.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => switch (items[i]) {
                    SeparadorDia(:final etiqueta) => SeparadorDiaView(
                      etiqueta: etiqueta,
                    ),
                    ItemMensaje(:final mensaje) => BurbujaMensaje(
                      key: ValueKey(mensaje.id),
                      mensaje: mensaje,
                      propio: mensaje.esDe(miUid),
                      nombreOtro: _nombreOtro,
                    ),
                  },
                );
              },
            ),
          ),
          CompositorMensaje(
            cerrado: cerrado,
            enviando: _enviando,
            onEnviar: (texto) => _enviar(miUid, chatId, texto),
          ),
        ],
      ),
    );
  }
}

/// Se muestra si se navega al chat sin [ChatArgs].
class ChatSinDatosScreen extends StatelessWidget {
  const ChatSinDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No encontramos esta conversación',
        message: 'Abre el chat desde una encomienda o desde la pestaña Chats.',
      ),
    );
  }
}
