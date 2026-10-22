import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/network/api_client.dart';
import 'data/local/prefs.dart';
import 'data/models/resumen_calificaciones.dart';
import 'data/repositories/calificaciones_repository.dart';
import 'data/repositories/catalogo_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/chatbot_repository.dart';
import 'data/repositories/encomienda_repository.dart';
import 'data/repositories/usuario_repository.dart';
import 'data/repositories/viaje_repository.dart';
import 'data/services/auth_service.dart';
import 'features/session/session_controller.dart';

/// Inyección de dependencias con Riverpod. Las pantallas leen estos
/// providers; nunca crean clientes HTTP ni llaman a Firebase directamente.

/// Se sobrescribe en `main()` con la instancia ya cargada.
final prefsProvider = Provider<Prefs>(
  (ref) => throw UnimplementedError('prefsProvider se inicializa en main()'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(FirebaseAuth.instance),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  final client = ApiClient(
    baseUrl: Env.apiBaseUrl,
    tokenProvider: auth.idToken,
  );
  ref.onDispose(client.dispose);
  return client;
});

final usuarioRepositoryProvider = Provider<UsuarioRepository>(
  (ref) => UsuarioRepository(ref.watch(apiClientProvider)),
);

final catalogoRepositoryProvider = Provider<CatalogoRepository>(
  (ref) => CatalogoRepository(
    ref.watch(apiClientProvider),
    ref.watch(prefsProvider),
  ),
);

final calificacionesRepositoryProvider = Provider<CalificacionesRepository>(
  (ref) => CalificacionesRepository(ref.watch(apiClientProvider)),
);

final sessionProvider = Provider<SessionController>((ref) {
  final session = SessionController(
    auth: ref.watch(authServiceProvider),
    usuarios: ref.watch(usuarioRepositoryProvider),
    prefs: ref.watch(prefsProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});

final paisesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogoRepositoryProvider).paises(),
);

final resumenCalificacionesProvider =
    FutureProvider.family<ResumenCalificaciones, String>(
      (ref, uid) => ref.watch(calificacionesRepositoryProvider).resumen(uid),
    );

// ---- Contrato compartido para las prácticas 3–6 ----
// Cada funcionalidad declara sus propios providers en
// features/<funcionalidad>/<funcionalidad>_providers.dart.

final encomiendaRepositoryProvider = Provider<EncomiendaRepository>(
  (ref) => EncomiendaRepository(ref.watch(apiClientProvider)),
);

final viajeRepositoryProvider = Provider<ViajeRepository>(
  (ref) => ViajeRepository(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider)),
);

final chatbotRepositoryProvider = Provider<ChatbotRepository>(
  (ref) => ChatbotRepository(ref.watch(apiClientProvider)),
);

final ciudadesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogoRepositoryProvider).ciudades(),
);
