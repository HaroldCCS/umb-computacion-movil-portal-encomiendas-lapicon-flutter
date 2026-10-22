import '../../../core/utils/formatters.dart';

/// Mensaje de `chats/{chatId}/mensajes/{id}` en Firestore.
///
/// Es un modelo puro (sin Firebase) para poder probarlo: el servicio
/// convierte los `Timestamp` a `DateTime` antes de llamar a [fromMap].
class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.texto,
    required this.emisorUid,
    required this.fecha,
    this.pendiente = false,
  });

  final String id;
  final String texto;
  final String emisorUid;

  /// Hora del servidor o, mientras se envía, la hora local.
  final DateTime fecha;

  /// `true` mientras el `serverTimestamp` no ha sido confirmado
  /// (se muestra "Enviando…").
  final bool pendiente;

  factory MensajeChat.fromMap(
    String id,
    Map<String, dynamic> data, {
    bool pendienteDeEscritura = false,
    DateTime? ahora,
  }) {
    final servidor = leerFecha(data['creadoEn']);
    final local = leerFecha(data['creadoLocal']);
    return MensajeChat(
      id: id,
      texto: (data['texto'] ?? '').toString(),
      emisorUid: (data['emisorUid'] ?? '').toString(),
      fecha: servidor ?? local ?? ahora ?? DateTime.now(),
      pendiente: servidor == null || pendienteDeEscritura,
    );
  }

  bool esDe(String uid) => emisorUid == uid;
}

/// Acepta `DateTime`, milisegundos (`int`) o texto ISO 8601.
DateTime? leerFecha(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Elemento de la lista del chat: separador de día o mensaje.
sealed class ItemChat {
  const ItemChat();
}

final class SeparadorDia extends ItemChat {
  const SeparadorDia(this.dia, this.etiqueta);

  final DateTime dia;
  final String etiqueta;
}

final class ItemMensaje extends ItemChat {
  const ItemMensaje(this.mensaje);

  final MensajeChat mensaje;
}

/// Ordena los mensajes por fecha e inserta un separador cada vez que cambia
/// el día ("Hoy", "Ayer", "3 oct").
List<ItemChat> agruparPorDia(List<MensajeChat> mensajes, {DateTime? ahora}) {
  final ordenados = [...mensajes]..sort((a, b) => a.fecha.compareTo(b.fecha));
  final items = <ItemChat>[];
  DateTime? diaActual;
  for (final m in ordenados) {
    final local = m.fecha.toLocal();
    final dia = DateTime(local.year, local.month, local.day);
    if (diaActual == null || dia != diaActual) {
      diaActual = dia;
      items.add(SeparadorDia(dia, etiquetaDia(dia, ahora: ahora)));
    }
    items.add(ItemMensaje(m));
  }
  return items;
}

String etiquetaDia(DateTime dia, {DateTime? ahora}) {
  final now = ahora ?? DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);
  final d = DateTime(dia.year, dia.month, dia.day);
  final diff = hoy.difference(d).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return Fmt.fecha(d, corta: true);
}
