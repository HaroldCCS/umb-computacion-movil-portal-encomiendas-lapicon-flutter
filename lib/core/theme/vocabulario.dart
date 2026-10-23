import '../../data/models/rol.dart';

/// Un solo lugar para los textos que cambian según el rol (docs/08 §8.6-4),
/// en vez de condicionar textos por toda la app.
class Vocabulario {
  const Vocabulario._({
    required this.inicio,
    required this.crear,
    required this.tituloHero,
    required this.verbo,
    required this.contraparte,
  });

  factory Vocabulario.de(Rol rol) => switch (rol) {
    Rol.remitente => const Vocabulario._(
      inicio: 'Inicio',
      crear: 'Nueva encomienda',
      tituloHero: 'Tus envíos activos',
      verbo: 'Envías',
      contraparte: 'viajero',
    ),
    Rol.viajero => const Vocabulario._(
      inicio: 'Mi viaje',
      crear: 'Registrar viaje',
      tituloHero: 'Tu viaje',
      verbo: 'Llevas',
      contraparte: 'remitente',
    ),
  };

  /// Nombre de la primera pestaña.
  final String inicio;

  /// Acción principal del botón "+".
  final String crear;

  /// Etiqueta de la tarjeta principal.
  final String tituloHero;

  /// "Envías" / "Llevas" (p. ej. "Llevas 2 encomiendas").
  final String verbo;

  /// La otra parte de la entrega ("viajero" / "remitente").
  final String contraparte;

  /// "el viajero" / "el remitente".
  String get laContraparte => 'el $contraparte';
}
