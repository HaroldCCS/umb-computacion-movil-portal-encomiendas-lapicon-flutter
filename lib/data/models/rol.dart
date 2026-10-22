/// Rol con el que el usuario usa la app.
enum Rol {
  remitente(
    titulo: 'Quiero enviar',
    nombre: 'Remitente',
    descripcion: 'Publica tu encomienda y encuentra quién la lleve.',
  ),
  viajero(
    titulo: 'Voy a viajar',
    nombre: 'Viajero',
    descripcion: 'Registra tu vuelo y gana llevando encomiendas de tu ruta.',
  );

  const Rol({
    required this.titulo,
    required this.nombre,
    required this.descripcion,
  });

  final String titulo;
  final String nombre;
  final String descripcion;

  Rol get opuesto => this == Rol.remitente ? Rol.viajero : Rol.remitente;

  /// Acepta "remitente", "Viajero", etc. Devuelve null si no reconoce el valor.
  static Rol? tryParse(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final rol in Rol.values) {
      if (rol.name == normalized) return rol;
    }
    return null;
  }
}
