import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/encomienda.dart';
import '../../data/models/viaje.dart';
import '../../providers.dart';
import 'envios_logic.dart';

/// Mis encomiendas como remitente (`GET /api/encomiendas`).
/// Se refresca con `ref.invalidate(misEncomiendasProvider)`.
final misEncomiendasProvider = FutureProvider<List<Encomienda>>(
  (ref) => ref.watch(encomiendaRepositoryProvider).mias(),
);

/// Viajeros que salen de una ciudad (`GET /api/viajes/buscar?ciudad=`).
final viajerosPorOrigenProvider = FutureProvider.family<List<Viaje>, String>(
  (ref, ciudad) => ref.watch(viajeRepositoryProvider).buscarPorOrigen(ciudad),
);

/// Chip elegido en "Mis envíos". El Inicio lo cambia para llevar directo a
/// las entregadas.
final pestanaEnviosProvider =
    NotifierProvider<PestanaEnviosNotifier, PestanaEnvios>(
      PestanaEnviosNotifier.new,
    );

class PestanaEnviosNotifier extends Notifier<PestanaEnvios> {
  @override
  PestanaEnvios build() => PestanaEnvios.activas;

  void ir(PestanaEnvios pestana) => state = pestana;
}

/// Último estado visto de cada encomienda del remitente [uid]
/// (`remitente_estados_vistos_{uid}`); `null` si nunca se guardó.
final estadosVistosProvider =
    NotifierProvider.family<
      EstadosVistosNotifier,
      Map<String, String>?,
      String
    >(EstadosVistosNotifier.new);

class EstadosVistosNotifier extends Notifier<Map<String, String>?> {
  EstadosVistosNotifier(this.uid);

  final String uid;

  @override
  Map<String, String>? build() => ref.watch(prefsProvider).estadosVistos(uid);

  /// Al cargar la lista: todo queda visto menos las nuevas tomadas.
  Future<void> sincronizar(List<Encomienda> lista) =>
      _guardar(actualizarVistos(lista, state));

  /// Al abrir el detalle o tocar "Entendido".
  Future<void> marcarVistas(Iterable<Encomienda> vistas) =>
      _guardar({...?state, for (final e in vistas) e.id: e.estado.apiValue});

  Future<void> _guardar(Map<String, String> nuevo) async {
    final actual = state;
    if (actual != null &&
        actual.length == nuevo.length &&
        nuevo.entries.every((p) => actual[p.key] == p.value)) {
      return;
    }
    state = nuevo;
    await ref.read(prefsProvider).guardarEstadosVistos(uid, nuevo);
  }
}

/// Encomiendas que un viajero tomó y el remitente aún no vio (docs/11 §2G).
List<Encomienda> nuevasTomadasDe(WidgetRef ref) {
  final uid = ref.watch(sessionProvider).user?.uid;
  final lista = ref.watch(misEncomiendasProvider).value;
  if (uid == null || lista == null) return const [];
  return nuevasTomadas(lista, ref.watch(estadosVistosProvider(uid)));
}

/// En el `build` de Inicio y Envíos: cada vez que llega la lista, guarda como
/// visto todo menos las nuevas tomadas.
void escucharEstadosVistos(WidgetRef ref) {
  ref.listen(misEncomiendasProvider, (_, siguiente) {
    final lista = siguiente.value;
    final uid = ref.read(sessionProvider).user?.uid;
    if (lista == null || uid == null) return;
    // Fuera del build: no se cambia un provider mientras se dibuja.
    Future.microtask(
      () => ref.read(estadosVistosProvider(uid).notifier).sincronizar(lista),
    );
  });
}
