import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import 'chat_screen.dart';

/// Rutas del chat. Para abrir un chat desde otra funcionalidad:
/// `context.push(Routes.chat, extra: ChatArgs(otroUid: ..., encomienda: ...))`.
final List<RouteBase> chatRoutes = [
  GoRoute(
    path: Routes.chat,
    builder: (context, state) {
      final args = state.extra;
      if (args is! ChatArgs) return const ChatSinDatosScreen();
      return ChatScreen(args: args);
    },
  ),
];
