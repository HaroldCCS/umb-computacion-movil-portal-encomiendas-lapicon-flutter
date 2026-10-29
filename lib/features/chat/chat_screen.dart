import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/insignia.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/estado.dart';
import '../../data/models/rol.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers.dart';
import 'chat_providers.dart';
import 'chat_service.dart';
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

  /// Error del último envío: va encima del campo, junto a la acción.
  String? _error;

  /// Se marca al re-consultar el estado justo antes de enviar.
  bool _cerradoAlEnviar = false;

  String get _nombreOtro {
    final n = widget.args.otroNombre?.trim() ?? '';
    return n.isEmpty ? 'Chat' : n;
  }

  Future<bool> _enviar(String miUid, String chatId, String texto) async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      // Reto 4: verificar que el chat siga abierto antes de cada envío.
      try {
        final estado = await ref.read(chatRepositoryProvider).estado(chatId);
        if (estado == EstadoChat.cerrado) {
          if (mounted) setState(() => _cerradoAlEnviar = true);
          return false;
        }
      } on NetworkException catch (e) {
        if (mounted) setState(() => _error = e.message);
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
      if (mounted) setState(() => _error = mensajeErrorChat(error));
      return false;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
      backgroundColor: c.fondo,
      appBar: CupertinoNavigationBar(
        backgroundColor: c.fondo.withValues(alpha: .92),
        border: Border(bottom: BorderSide(color: c.separador, width: .5)),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(_nombreOtro, tam: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreOtro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.texto,
                    ),
                  ),
                  Text(
                    cerrado ? 'Chat cerrado' : 'Coordinen la entrega aquí',
                    style: TextStyle(fontSize: 12, color: c.texto2),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: RouteTicket(
                origen: encomienda.ciudadOrigen,
                destino: encomienda.ciudadDestino,
                compact: true,
                accent: c.marca,
                trailing: Insignia.encomienda(
                  encomienda.estado,
                  rol: encomienda.viajeroUid == miUid
                      ? Rol.viajero
                      : Rol.remitente,
                ),
              ),
            ),
          Expanded(
            child: switch (mensajes) {
              AsyncData(value: final lista) when lista.isEmpty => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Vacio(
                    titulo: 'Saluda a $_nombreOtro',
                    icono: Icons.waving_hand_outlined,
                    texto:
                        'Acuerden dónde y cuándo entregar el paquete. '
                        'Revisen juntos el contenido antes del viaje.',
                  ),
                ),
              ),
              AsyncData(value: final lista) => () {
                final items = agruparPorDia(lista).reversed.toList();
                // Lista invertida: el mensaje más reciente queda abajo y la
                // vista se mantiene al final cuando llegan mensajes nuevos.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
              }(),
              AsyncError(:final error) => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ErrorCarga(
                    mensaje: mensajeErrorChat(error),
                    alReintentar: () =>
                        ref.invalidate(mensajesChatProvider(chatId)),
                  ),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Aviso(_error!, tipo: TipoAviso.error),
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
    return const Pantalla(
      titulo: 'Chat',
      hijos: [
        Vacio(
          titulo: 'No encontramos esta conversación',
          icono: Icons.forum_outlined,
          texto: 'Abre el chat desde una encomienda o desde la pestaña Chats.',
        ),
      ],
    );
  }
}
