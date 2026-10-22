/// Estados de una encomienda (ver docs/03 §3.4). Son los únicos que acepta
/// `PUT /api/encomiendas/:id/estado` (confirmado 22-oct-2026): el backend no
/// tiene "cancelada"; retirar una encomienda la deja `vencida`.
enum EstadoEncomienda {
  disponible('Disponible'),
  tomada('En camino'),
  entregada('Entregada'),
  recibida('Recibida'),
  vencida('Vencida'),
  desconocido('Sin estado');

  const EstadoEncomienda(this.etiqueta);

  /// Texto para la persona (p. ej. `tomada` se muestra como "En camino").
  final String etiqueta;

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
enum EstadoViaje {
  disponible('Activo'),
  completado('Completado'),
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
