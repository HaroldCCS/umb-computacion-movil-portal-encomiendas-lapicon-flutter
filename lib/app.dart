import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/tema.dart';
import 'core/theme/app_tokens.dart';
import 'core/widgets/feedback_views.dart';
import 'core/widgets/toast.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref.watch(sessionProvider));
  ref.onDispose(router.dispose);
  return router;
});

class LapticonApp extends ConsumerWidget {
  const LapticonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final api = ref.watch(apiClientProvider);

    return MaterialApp.router(
      title: 'Lapticon',
      debugShowCheckedModeBanner: false,
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Avisos flotantes (toasts) arriba de todo y aviso global cuando el
      // backend tarda (arranque en frío de Render).
      builder: (context, child) => Toasts(
        child: Stack(
          children: [
            ?child,
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.paddingOf(context).bottom + 88,
              child: IgnorePointer(
                child: ServerWakingBanner(visible: api.serverWaking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
