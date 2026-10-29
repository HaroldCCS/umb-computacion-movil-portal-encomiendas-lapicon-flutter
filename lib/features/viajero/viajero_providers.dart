import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/viaje.dart';
import '../../data/repositories/encomienda_repository.dart';
import '../../providers.dart';
import 'viajero_local_store.dart';
import 'viajero_logic.dart';

/// Providers de la funcionalidad del viajero (Práctica 4).
/// Son `autoDispose`: al cerrar sesión se descartan y no se mezclan usuarios.

final viajeroLocalStoreProvider = FutureProvider<ViajeroLocalStore>(
  (ref) => ViajeroLocalStore.abrir(),
);

/// Mi viaje activo (`GET /api/viajes/disponible`) o `null`.
final miViajeProvider = FutureProvider.autoDispose<Viaje?>(
  (ref) => ref.watch(viajeRepositoryProvider).disponible(),
);

/// Historial (`GET /api/viajes`), más recientes primero.
final historialViajesProvider = FutureProvider.autoDispose<List<Viaje>>((
  ref,
) async {
  final lista = await ref.watch(viajeRepositoryProvider).mios();
  return lista.toList()..sort(
    (a, b) => (b.fechaViaje ?? DateTime(2000)).compareTo(
      a.fechaViaje ?? DateTime(2000),
    ),
  );
});

/// `GET /api/encomiendas/buscar` en la ruta de mi viaje activo. Explorar y
/// "Mis entregas" lo comparten, así que se pide una sola vez.
final busquedaEnMiRutaProvider =
    FutureProvider.autoDispose<BusquedaEncomiendas>((ref) async {
      final viaje = await ref.watch(miViajeProvider.future);
      if (viaje == null) return const BusquedaEncomiendas();
      return ref
          .watch(encomiendaRepositoryProvider)
          .buscar(origen: viaje.ciudadOrigen, destino: viaje.ciudadDestino);
    });

/// Encomiendas que tomé: las `tomadas` del servidor en mi ruta más las
/// guardadas en el teléfono, que siguen haciendo falta porque `buscar` deja de
/// traerlas al entregarlas (ver [combinarEntregas]).
final misEntregasProvider = FutureProvider.autoDispose<List<Encomienda>>((
  ref,
) async {
  final uid = ref.watch(sessionProvider).user?.uid;
  if (uid == null) return const [];
  final store = await ref.watch(viajeroLocalStoreProvider.future);
  final locales = store.entregas(uid);
  List<Encomienda> servidor;
  try {
    servidor = (await ref.watch(busquedaEnMiRutaProvider.future)).tomadas;
  } on AppException {
    // Sin servidor se muestran al menos las registradas en el teléfono.
    if (locales.isEmpty) rethrow;
    servidor = const [];
  }
  return combinarEntregas(servidor: servidor, locales: locales, uid: uid);
});

/// Encomiendas disponibles en la ruta de mi viaje activo, sin las que publiqué
/// yo (`buscar` sí las incluye).
final disponiblesEnMiRutaProvider =
    FutureProvider.autoDispose<List<Encomienda>>((ref) async {
      final busqueda = await ref.watch(busquedaEnMiRutaProvider.future);
      return paraTomar(
        busqueda.disponibles,
        ref.watch(sessionProvider).user?.uid,
      );
    });

/// Refresca todo lo del viajero después de una acción (tomar, entregar…).
void refrescarViajero(WidgetRef ref) {
  ref.invalidate(miViajeProvider);
  ref.invalidate(historialViajesProvider);
  ref.invalidate(busquedaEnMiRutaProvider);
  ref.invalidate(misEntregasProvider);
  ref.invalidate(disponiblesEnMiRutaProvider);
}
