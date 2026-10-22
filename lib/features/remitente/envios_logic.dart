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

/// Interpreta el valor escrito ("10", "12,5", "50000").
num? parseValor(String? texto) {
  final t = (texto ?? '').trim().replaceAll(' ', '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return num.tryParse(t);
}

String? validarValor(String? texto) {
  final v = parseValor(texto);
  if ((texto ?? '').trim().isEmpty) return 'Escribe cuánto pagas por llevarla.';
  if (v == null) return 'Usa solo números (p. ej. 10 o 12,50).';
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
