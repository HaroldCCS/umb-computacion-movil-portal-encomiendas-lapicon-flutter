import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/estado.dart';
import '../../providers.dart';
import 'chat_service.dart';
import 'models/conversacion.dart';
import 'models/mensaje_chat.dart';

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(FirebaseFirestore.instance),
);

/// Mensajes en tiempo real de un chat (por chatId).
final mensajesChatProvider = StreamProvider.autoDispose
    .family<List<MensajeChat>, String>(
      (ref, chatId) => ref.watch(chatServiceProvider).mensajes(chatId),
    );

/// Mis conversaciones (por mi uid).
final conversacionesProvider = StreamProvider.autoDispose
    .family<List<Conversacion>, String>(
      (ref, uid) => ref.watch(chatServiceProvider).conversaciones(uid),
    );

/// Estado abierto/cerrado según el backend (`/api/chats/estado/:chatId`).
final estadoChatProvider = FutureProvider.autoDispose
    .family<EstadoChat, String>(
      (ref, chatId) => ref.watch(chatRepositoryProvider).estado(chatId),
    );
