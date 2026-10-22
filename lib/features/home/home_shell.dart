import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/rol.dart';
import '../../providers.dart';
import '../chat/conversaciones_screen.dart';
import '../perfil/perfil_screen.dart';
import '../remitente/buscar_viajeros_screen.dart';
import '../remitente/envios_screen.dart';
import '../viajero/explorar_screen.dart';
import '../viajero/mi_viaje_screen.dart';

/// Inicio por rol con barra de navegación inferior (docs/07 §7.4).
/// Cada pestaña es la pantalla principal de una funcionalidad.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  Rol? _rolAnterior;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final rol = session.rol ?? Rol.remitente;
        if (_rolAnterior != rol) {
          _rolAnterior = rol;
          _index = 0; // al cambiar de rol se vuelve a la primera pestaña
        }
        final tabs = _tabs(rol);

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [for (final t in tabs) t.page],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label,
                ),
            ],
          ),
        );
      },
    );
  }

  List<_Tab> _tabs(Rol rol) {
    const chats = _Tab(
      label: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      page: ConversacionesScreen(),
    );
    const perfil = _Tab(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: PerfilScreen(),
    );
    return switch (rol) {
      Rol.remitente => const [
        _Tab(
          label: 'Envíos',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          page: EnviosScreen(),
        ),
        _Tab(
          label: 'Viajeros',
          icon: Icons.travel_explore_outlined,
          selectedIcon: Icons.travel_explore,
          page: BuscarViajerosScreen(),
        ),
        chats,
        perfil,
      ],
      Rol.viajero => const [
        _Tab(
          label: 'Mi viaje',
          icon: Icons.flight_outlined,
          selectedIcon: Icons.flight,
          page: MiViajeScreen(),
        ),
        _Tab(
          label: 'Explorar',
          icon: Icons.search,
          selectedIcon: Icons.manage_search,
          page: ExplorarScreen(),
        ),
        chats,
        perfil,
      ],
    };
  }
}

class _Tab {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
