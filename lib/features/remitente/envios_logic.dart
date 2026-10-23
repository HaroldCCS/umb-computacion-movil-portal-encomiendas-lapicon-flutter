import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';

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
const pasosEncomienda = ['Publicada', 'Tomada', 'Entregada', 'Calificada'];

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
    required this.enCamino,
    required this.disponibles,
    required this.entregadas,
    required this.porCalificar,
  });

  factory ResumenEnvios.de(List<Encomienda> lista, Set<String> calificadas) {
    final grupos = agruparEnvios(lista);
    final activas = grupos[PestanaEnvios.activas]!;
    final entregadas = grupos[PestanaEnvios.entregadas]!;
    return ResumenEnvios(
      enCamino: activas
          .where((e) => e.estado == EstadoEncomienda.tomada)
          .length,
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

  final int enCamino;
  final int disponibles;
  final int entregadas;
  final List<Encomienda> porCalificar;

  int get activas => enCamino + disponibles;

  /// Frase bajo la cifra de la tarjeta principal.
  String get nota {
    if (activas == 0) {
      return // Espacio de no separación: el "+" no queda solo en otra línea.
      'No tienes envíos activos. Publica uno con el botón\u00A0+.';
    }
    final partes = [
      if (enCamino > 0) '$enCamino ${enCamino == 1 ? 'va' : 'van'} en camino',
      if (disponibles > 0)
        '$disponibles ${disponibles == 1 ? 'espera' : 'esperan'} viajero',
    ];
    return '${partes.join(' · ')}.';
  }
}
