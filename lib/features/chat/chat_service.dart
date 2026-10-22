import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/conversacion.dart';
import 'models/mensaje_chat.dart';

/// Chat en tiempo real sobre Firestore (Práctica 5). Los mensajes NO pasan
/// por el backend; el backend solo dice si el chat sigue abierto.
///
/// Estructura (propuesta, pendiente de confirmar con el profesor):
/// - `chats/{chatId}`: participantes, nombres, encomiendaId, ruta,
///   ultimoMensaje, ultimoEmisorUid, actualizadoEn.
/// - `chats/{chatId}/mensajes/{autoId}`: texto, emisorUid, creadoEn
///   (serverTimestamp) y creadoLocal (ms, para ordenar mientras se envía).
class ChatService {
  ChatService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Mensajes del chat en tiempo real, del más antiguo al más reciente.
  /// Se ordena en el cliente para incluir los mensajes que aún se envían
  /// (su `creadoEn` llega en null hasta que el servidor lo confirma).
  Stream<List<MensajeChat>> mensajes(String chatId) {
    return _chats
        .doc(chatId)
        .collection('mensajes')
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
          final lista = snap.docs
              .map(
                (d) => MensajeChat.fromMap(
                  d.id,
                  convertirFechas(d.data()),
                  pendienteDeEscritura: d.metadata.hasPendingWrites,
                ),
              )
              .toList();
          lista.sort((a, b) => a.fecha.compareTo(b.fecha));
          return lista;
        });
  }

  /// Conversaciones donde participo, más recientes primero (orden en el
  /// cliente para no requerir un índice compuesto).
  Stream<List<Conversacion>> conversaciones(String miUid) {
    return _chats
        .where('participantes', arrayContains: miUid)
        .snapshots()
        .map(
          (snap) => Conversacion.ordenar(
            snap.docs
                .map(
                  (d) => Conversacion.fromMap(d.id, convertirFechas(d.data())),
                )
                .toList(),
          ),
        );
  }

  /// Envía un mensaje y actualiza el resumen del chat en una sola escritura
  /// atómica (batch).
  Future<void> enviar({
    required String chatId,
    required String emisorUid,
    required String receptorUid,
    required String texto,
    String? nombreEmisor,
    String? nombreReceptor,
    String? encomiendaId,
    String? ruta,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    final chatRef = _chats.doc(chatId);
    final mensajeRef = chatRef.collection('mensajes').doc();
    final participantes = [emisorUid, receptorUid]..sort();

    final batch = _db.batch();
    batch.set(chatRef, {
      'participantes': participantes,
      'nombres': {
        if (nombreEmisor != null && nombreEmisor.isNotEmpty)
          emisorUid: nombreEmisor,
        if (nombreReceptor != null && nombreReceptor.isNotEmpty)
          receptorUid: nombreReceptor,
      },
      'encomiendaId': ?encomiendaId,
      'ruta': ?ruta,
      'ultimoMensaje': limpio,
      'ultimoEmisorUid': emisorUid,
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(mensajeRef, {
      'texto': limpio,
      'emisorUid': emisorUid,
      'creadoEn': FieldValue.serverTimestamp(),
      'creadoLocal': DateTime.now().millisecondsSinceEpoch,
    });
    await batch.commit();
  }

  /// Cambia los `Timestamp` de Firestore por `DateTime` (modelos puros).
  static Map<String, dynamic> convertirFechas(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k, v is Timestamp ? v.toDate() : v));
  }
}

/// Traduce errores de Firestore a mensajes para la persona.
String mensajeErrorChat(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permiso para ver o escribir en este chat. '
            'Puede que las reglas de Firestore aún no lo permitan.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No hay conexión con el chat. Revisa tu internet.';
      case 'unauthenticated':
        return 'Tu sesión expiró. Vuelve a iniciar sesión.';
      case 'failed-precondition':
        return 'El chat necesita una configuración adicional en Firestore.';
    }
    return 'No pudimos cargar el chat (${error.code}).';
  }
  return 'No pudimos cargar el chat. Intenta de nuevo.';
}
