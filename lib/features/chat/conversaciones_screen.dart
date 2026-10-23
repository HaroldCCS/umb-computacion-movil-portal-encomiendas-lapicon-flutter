import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/grupo.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/presionable.dart';
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

    return Pantalla(
      titulo: 'Chats',
      conBarraPestanas: true,
      hijos: miUid == null
          ? const []
          : switch (ref.watch(conversacionesProvider(miUid))) {
              AsyncData(value: final lista) when lista.isEmpty => const [
                Vacio(
                  titulo: 'Aún no tienes conversaciones',
                  icono: Icons.forum_outlined,
                  texto:
                      'Cuando una encomienda sea tomada podrán coordinar la '
                      'entrega por aquí.',
                ),
              ],
              AsyncData(value: final lista) => [
                Grupo(
                  hijos: [
                    for (final conv in lista)
                      _FilaConversacion(conversacion: conv, miUid: miUid),
                  ],
                ),
              ],
              AsyncError(:final error) => [
                ErrorCarga(
                  mensaje: mensajeErrorChat(error),
                  alReintentar: () =>
                      ref.invalidate(conversacionesProvider(miUid)),
                ),
              ],
              _ => [const EsqueletoLista(cantidad: 4, alto: 72)],
            },
    );
  }
}

/// Fila de conversación: avatar, nombre, ruta, último mensaje y hora.
class _FilaConversacion extends StatelessWidget {
  const _FilaConversacion({required this.conversacion, required this.miUid});

  final Conversacion conversacion;
  final String miUid;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final otroUid = conversacion.otroUid(miUid);
    final nombre = conversacion.nombreDe(otroUid);
    final ultimo = conversacion.ultimoMensaje ?? 'Sin mensajes todavía';
    final prefijo = conversacion.ultimoEmisorUid == miUid ? 'Tú: ' : '';
    final cuando = Fmt.relativo(conversacion.actualizadoEn);
    final ruta = conversacion.ruta;
    void abrir() => context.push(
      Routes.chat,
      extra: ChatArgs(otroUid: otroUid!, otroNombre: nombre),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Presionable(
          onTap: otroUid == null ? null : abrir,
          escala: 0.99,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Avatar(nombre, tam: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: c.texto,
                              ),
                            ),
                          ),
                          if (cuando.isNotEmpty)
                            Text(
                              cuando,
                              style: TextStyle(fontSize: 13, color: c.texto2),
                            ),
                        ],
                      ),
                      if (ruta != null)
                        Text(
                          ruta.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: c.marca,
                          ),
                        ),
                      Text(
                        '$prefijo$ultimo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: c.texto2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
