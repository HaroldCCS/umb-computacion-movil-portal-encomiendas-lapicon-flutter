import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Ids de las encomiendas que el usuario [uid] ya calificó (guardadas en el
/// teléfono). Alimenta los contadores y avisos de "por calificar".
final calificadasProvider =
    NotifierProvider.family<CalificadasNotifier, Set<String>, String>(
      CalificadasNotifier.new,
    );

class CalificadasNotifier extends Notifier<Set<String>> {
  CalificadasNotifier(this.uid);

  final String uid;

  @override
  Set<String> build() => ref.watch(prefsProvider).calificadas(uid);

  Future<void> marcar(String encomiendaId) async {
    await ref.read(prefsProvider).marcarCalificada(uid, encomiendaId);
    state = {...state, encomiendaId};
  }
}

/// Calificadas del usuario con sesión (vacío sin sesión).
Set<String> calificadasDe(WidgetRef ref) {
  final uid = ref.watch(sessionProvider).user?.uid;
  return uid == null ? const {} : ref.watch(calificadasProvider(uid));
}
