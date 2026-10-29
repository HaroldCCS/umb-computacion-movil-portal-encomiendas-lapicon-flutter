import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/encomienda.dart';
import '../../data/models/viaje.dart';
import '../../providers.dart';
import 'envios_logic.dart';

/// Mis encomiendas como remitente (`GET /api/encomiendas`), con el nombre del
/// viajero cuando se conoce: `GET /api/viajes/disponibles` lo da mientras su
/// viaje siga disponible (docs/11 §2C).
/// Se refresca con `ref.invalidate(misEncomiendasProvider)`.
final misEncomiendasProvider = FutureProvider<List<Encomienda>>((ref) async {
  final viajes = ref.watch(viajeRepositoryProvider);
  return conNombresDeViajeros(
    await ref.watch(encomiendaRepositoryProvider).mias(),
    viajes.disponiblesEnRuta,
  );
});

/// Viajeros con viaje disponible en una ruta, con nombre (pública).
final viajerosEnRutaProvider =
    FutureProvider.family<List<Viaje>, ({String origen, String destino})>(
      (ref, ruta) => ref
          .watch(viajeRepositoryProvider)
          .disponiblesEnRuta(ruta.origen, ruta.destino),
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

/// Si la IA no responde en este tiempo, el detalle sigue sin sugerencias
/// (una vez tardó más de 120 s).
const esperaSugerencias = Duration(seconds: 15);

/// Viajeros sugeridos por IA para una encomienda disponible (docs/11 §2F),
/// con su nombre cuando `viajes/disponibles` lo da. Nunca bloquea: con error o
/// demora, falla sola.
final viajerosSugeridosProvider = FutureProvider.autoDispose
    .family<List<SugerenciaViajero>, Encomienda>(
      (ref, e) async {
        final sugeridos = await ref
            .watch(encomiendaRepositoryProvider)
            .emparejar(
              ciudadOrigen: e.ciudadOrigen,
              ciudadDestino: e.ciudadDestino,
              fecha: e.fechaVencimiento ?? DateTime.now(),
              valor: e.valor,
            )
            .timeout(esperaSugerencias);
        final viajeros = await ref
            .watch(viajeRepositoryProvider)
            .disponiblesEnRuta(e.ciudadOrigen, e.ciudadDestino)
            .catchError((Object _) => const <Viaje>[]);
        return sugerenciasParaMostrar(
          [
            for (final s in sugeridos)
              (
                viajeroUid: s.viajeroUid,
                afinidad: s.afinidad,
                fechaViaje: s.fechaViaje,
              ),
          ],
          viajeros,
          ref.watch(sessionProvider).user?.uid,
        );
      },
      // Sin reintentos automáticos: si falla, se dice y la persona reintenta.
      retry: (_, _) => null,
    );
