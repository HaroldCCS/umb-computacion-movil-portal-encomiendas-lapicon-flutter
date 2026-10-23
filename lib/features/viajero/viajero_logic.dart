/// Lógica pura del viajero (sin Flutter), para poder probarla aislada.
library;

import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/viaje.dart';

/// Código de aerolínea (2 caracteres IATA, letras o dígitos) + 1 a 4 dígitos
/// + sufijo opcional. Acepta "AA123", "AV 24", "4C5021", "LA2401A".
final RegExp _vuelo = RegExp(r'^[A-Z0-9]{2}\d{1,4}[A-Z]?$');

/// Quita espacios y guiones y pasa a mayúsculas: "av 24" → "AV24".
String normalizarVuelo(String value) =>
    value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

/// Validador de formulario para el número de vuelo.
String? validarNumeroVuelo(String? value) {
  final v = normalizarVuelo(value ?? '');
  if (v.isEmpty) return 'Escribe el número de vuelo.';
  if (!RegExp(r'[A-Z]').hasMatch(v.substring(0, v.length.clamp(0, 2)))) {
    return 'Empieza con el código de la aerolínea (p. ej. AV, AA, LA).';
  }
  if (!_vuelo.hasMatch(v)) {
    return 'Revisa el número: debe verse como AV24 o AA123.';
  }
  return null;
}

/// Clave para recordar que un vuelo se verificó con AeroDataBox.
String claveVuelo(String numero, DateTime? fecha) =>
    '${normalizarVuelo(numero)}|${fecha == null ? '' : Viaje.fechaIso(fecha)}';

/// "Mis entregas": no hay endpoint propio, así que se combinan
/// 1. las encomiendas de `GET /api/encomiendas` cuyo viajero soy yo (si el
///    backend también devuelve las que tomé), y
/// 2. las que tomé desde este teléfono (registro local), por si el backend
///    solo devuelve las del remitente.
/// Si una encomienda está en ambos lados, gana la del servidor (estado fresco).
List<Encomienda> combinarEntregas({
  required List<Encomienda> servidor,
  required List<Encomienda> locales,
  required String uid,
}) {
  final idsLocales = {for (final e in locales) e.id};
  final porId = <String, Encomienda>{};
  for (final e in locales) {
    porId[e.id] = e;
  }
  for (final e in servidor) {
    final esMia = e.viajeroUid == uid || idsLocales.contains(e.id);
    // Una encomienda propia como remitente no es una "entrega".
    if (esMia && e.remitenteUid != uid) porId[e.id] = e;
  }
  final lista = porId.values.toList()
    ..sort((a, b) {
      final p = _prioridad(a.estado).compareTo(_prioridad(b.estado));
      if (p != 0) return p;
      final fa = a.creadaEn ?? DateTime(2000);
      final fb = b.creadaEn ?? DateTime(2000);
      return fb.compareTo(fa);
    });
  return lista;
}

int _prioridad(EstadoEncomienda e) => switch (e) {
  EstadoEncomienda.tomada => 0,
  EstadoEncomienda.disponible => 1,
  EstadoEncomienda.entregada || EstadoEncomienda.recibida => 2,
  _ => 3,
};

/// Encomiendas que el viajero puede tomar: disponibles y que no son suyas.
/// `/disponibles` no trae el uid del remitente, por eso también se excluyen
/// los [idsPropios] (las que publiqué como remitente).
List<Encomienda> paraTomar(
  List<Encomienda> lista,
  String? uid, {
  Set<String> idsPropios = const {},
}) => lista
    .where(
      (e) =>
          (e.estado == EstadoEncomienda.disponible ||
              e.estado == EstadoEncomienda.desconocido) &&
          (uid == null || e.remitenteUid != uid) &&
          !idsPropios.contains(e.id),
    )
    .toList();

/// ¿La encomienda la tomé yo?
bool tomadaPorMi(Encomienda e, String? uid, Set<String> idsLocales) =>
    uid != null && (e.viajeroUid == uid || idsLocales.contains(e.id));

/// Copia de la encomienda con otro estado (y viajero, si se indica).
Encomienda conEstado(
  Encomienda e,
  EstadoEncomienda estado, {
  String? viajeroUid,
}) => Encomienda(
  id: e.id,
  ciudadOrigen: e.ciudadOrigen,
  ciudadDestino: e.ciudadDestino,
  observaciones: e.observaciones,
  moneda: e.moneda,
  valor: e.valor,
  estado: estado,
  remitenteUid: e.remitenteUid,
  viajeroUid: viajeroUid ?? e.viajeroUid,
  remitenteNombre: e.remitenteNombre,
  viajeroNombre: e.viajeroNombre,
  fechaVencimiento: e.fechaVencimiento,
  creadaEn: e.creadaEn,
);

/// La respuesta de `PUT /:id/estado` trae el uid del remitente pero no su
/// nombre (que sí venía en `/disponibles`): se completa con lo que ya había.
Encomienda conservarNombres(Encomienda nueva, Encomienda previa) => Encomienda(
  id: nueva.id,
  ciudadOrigen: nueva.ciudadOrigen,
  ciudadDestino: nueva.ciudadDestino,
  observaciones: nueva.observaciones,
  moneda: nueva.moneda,
  valor: nueva.valor,
  estado: nueva.estado,
  remitenteUid: nueva.remitenteUid ?? previa.remitenteUid,
  viajeroUid: nueva.viajeroUid ?? previa.viajeroUid,
  remitenteNombre: nueva.remitenteNombre ?? previa.remitenteNombre,
  viajeroNombre: nueva.viajeroNombre ?? previa.viajeroNombre,
  fechaVencimiento: nueva.fechaVencimiento ?? previa.fechaVencimiento,
  creadaEn: nueva.creadaEn ?? previa.creadaEn,
);

/// Serializa una encomienda con las mismas claves que lee
/// [Encomienda.fromJson] (para el registro local).
Map<String, dynamic> encomiendaToJson(Encomienda e) => {
  '_id': e.id,
  'ciudadOrigen': e.ciudadOrigen,
  'ciudadDestino': e.ciudadDestino,
  'observaciones': e.observaciones,
  'moneda': e.moneda,
  'valor': e.valor,
  'estado': e.estado.name,
  if (e.remitenteUid != null)
    'remitente': {'uid': e.remitenteUid, 'nombre': e.remitenteNombre ?? ''},
  if (e.viajeroUid != null)
    'viajero': {'uid': e.viajeroUid, 'nombre': e.viajeroNombre ?? ''},
  if (e.fechaVencimiento != null)
    'fechaVencimiento': e.fechaVencimiento!.toIso8601String(),
  if (e.creadaEn != null) 'createdAt': e.creadaEn!.toIso8601String(),
};

/// Extrae datos legibles de la respuesta de `/api/vuelos/:numero/:fecha`
/// (forma no confirmada; se reconocen formatos comunes de AeroDataBox).
List<String> resumenVuelo(Map<String, dynamic> json) {
  String? nombre(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is Map) {
      for (final k in const [
        'name',
        'nombre',
        'shortName',
        'municipalityName',
      ]) {
        final x = v[k];
        if (x is String && x.trim().isNotEmpty) return x.trim();
      }
      final airport = v['airport'] ?? v['aeropuerto'];
      if (airport != null) return nombre(airport);
    }
    return null;
  }

  final datos = <String>[];
  final aerolinea = nombre(json['airline'] ?? json['aerolinea']);
  if (aerolinea != null) datos.add('Aerolínea: $aerolinea');
  final salida = nombre(json['departure'] ?? json['salida'] ?? json['origen']);
  if (salida != null) datos.add('Sale de: $salida');
  final llegada = nombre(json['arrival'] ?? json['llegada'] ?? json['destino']);
  if (llegada != null) datos.add('Llega a: $llegada');
  return datos;
}

/// Tomadas que todavía debo entregar.
List<Encomienda> porEntregar(List<Encomienda> entregas) => [
  for (final e in entregas)
    if (e.estado == EstadoEncomienda.tomada) e,
];

/// Entregadas que aún no califiqué (y de las que sé quién es el remitente).
List<Encomienda> porCalificarViajero(
  List<Encomienda> entregas,
  Set<String> calificadas,
) => [
  for (final e in entregas)
    if (e.estado.finalizada &&
        e.remitenteUid != null &&
        !calificadas.contains(e.id))
      e,
];

/// Lo que me pagan por las encomiendas tomadas o entregadas, por moneda
/// (`{'USD': 40, 'COP': 50000}`), sin mezclar monedas.
Map<String, num> gananciasPorMoneda(List<Encomienda> entregas) {
  final total = <String, num>{};
  for (final e in entregas) {
    if (e.estado == EstadoEncomienda.tomada || e.estado.finalizada) {
      final m = e.moneda.toUpperCase();
      total[m] = (total[m] ?? 0) + e.valor;
    }
  }
  return total;
}

/// Orden de la lista de Explorar. No se ordena por valor: comparar USD con
/// COP sería engañoso.
enum OrdenExplorar {
  recientes('Más recientes'),
  vencenPronto('Vencen pronto');

  const OrdenExplorar(this.titulo);

  final String titulo;
}

/// Ordena sin modificar [lista]. Las que no tienen fecha van al final.
List<Encomienda> ordenarDisponibles(List<Encomienda> lista, OrdenExplorar o) {
  int porFecha(DateTime? a, DateTime? b, {required bool ascendente}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return ascendente ? a.compareTo(b) : b.compareTo(a);
  }

  return [...lista]..sort(
    (a, b) => switch (o) {
      OrdenExplorar.recientes => porFecha(
        a.creadaEn,
        b.creadaEn,
        ascendente: false,
      ),
      OrdenExplorar.vencenPronto => porFecha(
        a.fechaVencimiento,
        b.fechaVencimiento,
        ascendente: true,
      ),
    },
  );
}
