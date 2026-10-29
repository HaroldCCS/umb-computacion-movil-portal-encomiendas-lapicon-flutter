import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/viaje.dart';

/// Lógica pura del remitente (sin Flutter) para poder probarla.

/// Pestañas de "Mis envíos".
enum PestanaEnvios {
  activas('Activas'),
  entregadas('Entregadas'),
  historial('Historial');

  const PestanaEnvios(this.titulo);

  final String titulo;

  static PestanaEnvios de(EstadoEncomienda estado) => switch (estado) {
    EstadoEncomienda.disponible || EstadoEncomienda.tomada => activas,
    EstadoEncomienda.entregada || EstadoEncomienda.recibida => entregadas,
    EstadoEncomienda.vencida || EstadoEncomienda.desconocido => historial,
  };
}

/// Agrupa las encomiendas por pestaña; dentro de cada una, las más
/// recientes primero (las que no tienen fecha van al final).
Map<PestanaEnvios, List<Encomienda>> agruparEnvios(List<Encomienda> lista) {
  final grupos = {for (final p in PestanaEnvios.values) p: <Encomienda>[]};
  for (final e in lista) {
    grupos[PestanaEnvios.de(e.estado)]!.add(e);
  }
  for (final g in grupos.values) {
    g.sort((a, b) {
      final fa = a.creadaEn, fb = b.creadaEn;
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;
      return fb.compareTo(fa);
    });
  }
  return grupos;
}

/// Pasos de la línea de tiempo del detalle.
const pasosEncomienda = [
  'Publicada',
  'Tomada por un viajero',
  'Entregada',
  'Calificada',
];

/// Índice del paso actual (0..3) o `null` si el estado es terminal sin
/// entrega (vencida / desconocido).
int? pasoActual(EstadoEncomienda estado, {bool calificada = false}) =>
    switch (estado) {
      EstadoEncomienda.disponible => 0,
      EstadoEncomienda.tomada => 1,
      EstadoEncomienda.entregada ||
      EstadoEncomienda.recibida => calificada ? 3 : 2,
      _ => null,
    };

/// Valor del `CampoMonto` ("1.234.567" → 1234567). `null` si está vacío.
/// Solo enteros: el pago al viajero no lleva centavos.
int? parseValor(String? texto) {
  final digitos = (texto ?? '').replaceAll(RegExp(r'[^\d]'), '');
  return digitos.isEmpty ? null : int.tryParse(digitos);
}

String? validarValor(String? texto) {
  final v = parseValor(texto);
  if (v == null) return 'Escribe cuánto pagas por llevarla.';
  if (v <= 0) return 'El valor debe ser mayor que cero.';
  if (v > 100000000) return 'El valor es demasiado alto.';
  return null;
}

String? validarObservaciones(String? texto) {
  final t = (texto ?? '').trim();
  if (t.isEmpty) return 'Cuéntale al viajero qué envías.';
  if (t.length < 3) return 'Describe un poco más el contenido.';
  if (t.length > 200) return 'Máximo 200 caracteres.';
  return null;
}

/// Origen y destino deben ser distintos.
String? validarRuta(String origen, String destino) {
  if (origen.trim().isEmpty || destino.trim().isEmpty) return null;
  if (origen.trim().toLowerCase() == destino.trim().toLowerCase()) {
    return 'El origen y el destino no pueden ser la misma ciudad.';
  }
  return null;
}

/// Copia de la encomienda con otro estado (el modelo no tiene copyWith).
Encomienda conEstado(Encomienda e, EstadoEncomienda estado) => Encomienda(
  id: e.id,
  ciudadOrigen: e.ciudadOrigen,
  ciudadDestino: e.ciudadDestino,
  observaciones: e.observaciones,
  moneda: e.moneda,
  valor: e.valor,
  estado: estado,
  remitenteUid: e.remitenteUid,
  viajeroUid: e.viajeroUid,
  remitenteNombre: e.remitenteNombre,
  viajeroNombre: e.viajeroNombre,
  fechaVencimiento: e.fechaVencimiento,
  creadaEn: e.creadaEn,
);

/// Lo que muestra el Inicio del remitente (docs/08 §8.4).
class ResumenEnvios {
  const ResumenEnvios({
    required this.tomadas,
    required this.disponibles,
    required this.entregadas,
    required this.porCalificar,
  });

  factory ResumenEnvios.de(List<Encomienda> lista, Set<String> calificadas) {
    final grupos = agruparEnvios(lista);
    final activas = grupos[PestanaEnvios.activas]!;
    final entregadas = grupos[PestanaEnvios.entregadas]!;
    return ResumenEnvios(
      tomadas: activas.where((e) => e.estado == EstadoEncomienda.tomada).length,
      disponibles: activas
          .where((e) => e.estado == EstadoEncomienda.disponible)
          .length,
      entregadas: entregadas.length,
      // Solo se puede calificar si se sabe quién la llevó.
      porCalificar: [
        for (final e in entregadas)
          if (e.viajeroUid != null && !calificadas.contains(e.id)) e,
      ],
    );
  }

  /// Activas que ya tienen viajero (`tomada`).
  final int tomadas;
  final int disponibles;
  final int entregadas;
  final List<Encomienda> porCalificar;

  int get activas => tomadas + disponibles;

  /// Frase bajo la cifra de la tarjeta principal.
  String get nota {
    if (activas == 0) {
      return // Espacio de no separación: el "+" no queda solo en otra línea.
      'No tienes envíos activos. Publica uno con el botón\u00A0+.';
    }
    final partes = [
      if (tomadas > 0)
        '$tomadas ${tomadas == 1 ? 'tomada' : 'tomadas'} por un viajero',
      if (disponibles > 0)
        '$disponibles ${disponibles == 1 ? 'espera' : 'esperan'} viajero',
    ];
    return '${partes.join(' · ')}.';
  }
}

/// Encomiendas que un viajero tomó desde la última vez que el remitente las
/// vio (`remitente_estados_vistos_{uid}`, mapa `id → estado`): estaban
/// `disponible` (o no las conocía) y ahora están `tomada`. La primera vez
/// (sin mapa) no avisa de nada, para no soltar todo de golpe.
List<Encomienda> nuevasTomadas(
  List<Encomienda> lista,
  Map<String, String>? vistos,
) {
  if (vistos == null) return const [];
  return [
    for (final e in lista)
      if (e.estado == EstadoEncomienda.tomada &&
          (vistos[e.id] == null || vistos[e.id] == 'disponible'))
        e,
  ];
}

/// El mapa a guardar después de cargar: todo queda como visto, menos las
/// nuevas tomadas, que esperan a que el remitente abra el detalle o toque
/// "Entendido".
Map<String, String> actualizarVistos(
  List<Encomienda> lista,
  Map<String, String>? vistos,
) {
  final pendientes = {for (final e in nuevasTomadas(lista, vistos)) e.id};
  return {
    for (final e in lista)
      if (!pendientes.contains(e.id))
        e.id: e.estado.apiValue
      else if (vistos?[e.id] != null)
        e.id: vistos![e.id]!,
  };
}

/// Completa `viajeroNombre` de las encomiendas con viajero: se pide una vez
/// por ruta `viajes/disponibles` y se cruza por `uid`. Si falla o el viaje ya
/// se cerró, quedan sin nombre.
Future<List<Encomienda>> conNombresDeViajeros(
  List<Encomienda> lista,
  Future<List<Viaje>> Function(String origen, String destino) viajerosEnRuta,
) async {
  final rutas = {
    for (final e in lista)
      if (e.viajeroUid != null && e.viajeroNombre == null)
        (e.ciudadOrigen, e.ciudadDestino),
  };
  final nombres = <String, String>{};
  await Future.wait([
    for (final (o, d) in rutas)
      viajerosEnRuta(o, d)
          .then((viajes) {
            for (final v in viajes) {
              if (v.viajeroUid != null && v.viajeroNombre != null) {
                nombres[v.viajeroUid!] = v.viajeroNombre!;
              }
            }
          })
          // Sin nombre se muestra "Un viajero": no vale la pena fallar la
          // lista por esto.
          .catchError((Object _) {}),
  ]);
  return [
    for (final e in lista)
      if (e.viajeroNombre == null && nombres[e.viajeroUid] != null)
        _conNombre(e, nombres[e.viajeroUid]!)
      else
        e,
  ];
}

Encomienda _conNombre(Encomienda e, String nombre) => Encomienda(
  id: e.id,
  ciudadOrigen: e.ciudadOrigen,
  ciudadDestino: e.ciudadDestino,
  observaciones: e.observaciones,
  moneda: e.moneda,
  valor: e.valor,
  estado: e.estado,
  remitenteUid: e.remitenteUid,
  remitenteNombre: e.remitenteNombre,
  viajeroUid: e.viajeroUid,
  viajeroNombre: nombre,
  fechaVencimiento: e.fechaVencimiento,
  creadaEn: e.creadaEn,
);

/// Una sugerencia lista para mostrar: con nombre si `viajes/disponibles` lo da.
typedef SugerenciaViajero = ({
  String viajeroUid,
  String? nombre,
  double afinidad,
  DateTime? fechaViaje,
});

/// Viajeros sugeridos para una encomienda: sin el propio remitente (puede
/// tener un viaje en esa ruta), uno por viajero, los de más afinidad primero y
/// como mucho [max].
List<SugerenciaViajero> sugerenciasParaMostrar(
  List<({String viajeroUid, double afinidad, DateTime? fechaViaje})> sugeridos,
  List<Viaje> viajeros,
  String? miUid, {
  int max = 3,
}) {
  final nombres = {
    for (final v in viajeros)
      if (v.viajeroUid != null) v.viajeroUid!: v.viajeroNombre,
  };
  final vistos = <String>{};
  final orden = [...sugeridos]
    ..sort((a, b) => b.afinidad.compareTo(a.afinidad));
  return [
    for (final s in orden)
      if (s.viajeroUid != miUid && vistos.add(s.viajeroUid))
        (
          viajeroUid: s.viajeroUid,
          nombre: nombres[s.viajeroUid],
          afinidad: s.afinidad,
          fechaViaje: s.fechaViaje,
        ),
  ].take(max).toList();
}
