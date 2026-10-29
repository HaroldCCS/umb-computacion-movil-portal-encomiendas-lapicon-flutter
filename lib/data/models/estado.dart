import 'rol.dart';

/// Estados de una encomienda (ver docs/03 §3.4). Son los únicos que acepta
/// `PUT /api/encomiendas/:id/estado` (confirmado 22-oct-2026): el backend no
/// tiene "cancelada"; retirar una encomienda la deja `vencida`.
enum EstadoEncomienda {
  disponible('Disponible'),
  tomada('Tomada'),
  entregada('Entregada'),
  recibida('Recibida'),
  vencida('Vencida'),
  desconocido('Sin estado');

  const EstadoEncomienda(this.etiqueta);

  /// Texto para el remitente. Para quien la lleva, ver [etiquetaPara].
  final String etiqueta;

  /// Etiqueta según quién mira (docs/11 §2G): `tomada` es "Tomada" para el
  /// remitente (alguien aceptó llevarla) y "La llevas tú" para el viajero que
  /// la tomó. `Rol.viajero` significa "la llevo yo"; para una tomada por otra
  /// persona, usar `Rol.remitente`.
  String etiquetaPara(Rol rol) =>
      this == tomada && rol == Rol.viajero ? 'La llevas tú' : etiqueta;

  /// Valor que espera el backend en `PUT /api/encomiendas/:id/estado`.
  String get apiValue => name;

  bool get activa => this == disponible || this == tomada;

  /// Ya llegó a su destino (entregada por el viajero o recibida).
  bool get finalizada => this == entregada || this == recibida;

  static EstadoEncomienda parse(Object? value) {
    final v = value?.toString().trim().toLowerCase() ?? '';
    for (final e in values) {
      if (e.name == v) return e;
    }
    return desconocido;
  }
}

/// Estados de un viaje.
/// `contactado` solo aparece en el Swagger oficial (el PATCH lo rechaza); se
/// muestra si llega.
enum EstadoViaje {
  disponible('Activo'),
  completado('Completado'),
  cancelado('Cancelado'),
  contactado('Contactado'),
  desconocido('Sin estado');

  const EstadoViaje(this.etiqueta);

  final String etiqueta;

  static EstadoViaje parse(Object? value) {
    final v = value?.toString().trim().toLowerCase() ?? '';
    for (final e in values) {
      if (e.name == v) return e;
    }
    return desconocido;
  }
}

/// Estado del chat según `GET /api/chats/estado/:chatId`.
enum EstadoChat { abierto, cerrado }
