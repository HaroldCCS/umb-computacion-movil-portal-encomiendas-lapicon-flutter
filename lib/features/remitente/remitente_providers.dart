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
