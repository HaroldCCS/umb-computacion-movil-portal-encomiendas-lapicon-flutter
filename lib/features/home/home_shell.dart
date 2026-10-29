import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vocabulario.dart';
import '../../core/widgets/barra_pestanas.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/calificaciones_providers.dart';
import '../chat/conversaciones_screen.dart';
import '../perfil/perfil_screen.dart';
import '../remitente/envios_logic.dart';
import '../remitente/envios_screen.dart';
import '../remitente/inicio_remitente_screen.dart';
import '../remitente/remitente_providers.dart';
import '../viajero/explorar_screen.dart';
import '../viajero/mi_viaje_screen.dart';
import '../viajero/viajero_logic.dart';
import '../viajero/viajero_providers.dart';
import '../viajero/viajero_routes.dart';
import 'home_providers.dart';

/// Inicio por rol con la barra de pestañas flotante y el botón "+" de la
/// acción principal (docs/08 §8.4):
///
///   REMITENTE  Inicio · Envíos · Chats · Perfil      (+) Nueva encomienda
///   VIAJERO    Mi viaje · Explorar · Chats · Perfil  (+) Registrar viaje,
///              solo si no hay viaje activo.
///
/// Los contadores avisan de algo por hacer: entregas por calificar
/// (remitente) y encomiendas por entregar (viajero).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  Rol? _rolAnterior;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final rol = session.rol ?? Rol.remitente;
        var actual = ref.watch(pestanaInicioProvider);
        if (_rolAnterior != rol) {
          // Al cambiar de rol se vuelve a la primera pestaña.
          final primera = _rolAnterior == null;
          _rolAnterior = rol;
          if (!primera && actual != Pestanas.inicio) {
            actual = Pestanas.inicio;
            Future.microtask(
              () => ref.read(pestanaInicioProvider.notifier).ir(actual),
            );
          }
        }

        final paginas = switch (rol) {
          Rol.remitente => const [
            InicioRemitenteScreen(),
            EnviosScreen(),
            ConversacionesScreen(),
            PerfilScreen(),
          ],
          Rol.viajero => const [
            MiViajeScreen(),
            ExplorarScreen(),
            ConversacionesScreen(),
            PerfilScreen(),
          ],
        };

        return Scaffold(
          // El contenido pasa por debajo de la barra de vidrio; cada
          // pestaña deja `Medidas.bajoBarra` de relleno inferior.
          extendBody: true,
          body: IndexedStack(index: actual, children: paginas),
          bottomNavigationBar: BarraPestanas(
            items: _items(rol),
            actual: actual,
            onCambio: ref.read(pestanaInicioProvider.notifier).ir,
            onMas: _accionPrincipal(rol),
            etiquetaMas: Vocabulario.de(rol).crear,
          ),
        );
      },
    );
  }

  List<PestanaItem> _items(Rol rol) {
    const chats = PestanaItem(
      Icons.chat_bubble_outline,
      'Chats',
      iconoActivo: Icons.chat_bubble,
    );
    const perfil = PestanaItem(
      Icons.person_outline,
      'Perfil',
      iconoActivo: Icons.person,
    );
    switch (rol) {
      case Rol.remitente:
        final porCalificar = switch (ref.watch(misEncomiendasProvider)) {
          AsyncData(:final value) => ResumenEnvios.de(
            value,
            calificadasDe(ref),
          ).porCalificar.length,
          _ => 0,
        };
        final nuevas = nuevasTomadasDe(ref).length;
        final etiquetas = [
          if (nuevas > 0) '$nuevas ${nuevas == 1 ? 'nueva' : 'nuevas'}',
          if (porCalificar > 0) '$porCalificar por calificar',
        ];
        return [
          const PestanaItem(
            Icons.home_outlined,
            'Inicio',
            iconoActivo: Icons.home_rounded,
          ),
          PestanaItem(
            Icons.inventory_2_outlined,
            'Envíos',
            iconoActivo: Icons.inventory_2,
            contador: nuevas + porCalificar,
            etiquetaContador: etiquetas.join(' · '),
          ),
          chats,
          perfil,
        ];
      case Rol.viajero:
        final pendientes = switch (ref.watch(misEntregasProvider)) {
          AsyncData(:final value) => porEntregar(value).length,
          _ => 0,
        };
        return [
          PestanaItem(
            Icons.flight_outlined,
            'Mi viaje',
            iconoActivo: Icons.flight,
            contador: pendientes,
            etiquetaContador: '$pendientes por entregar',
          ),
          const PestanaItem(
            Icons.search,
            'Explorar',
            iconoActivo: Icons.manage_search,
          ),
          chats,
          perfil,
        ];
    }
  }

  /// El "+" de la barra. El viajero con viaje activo no lo ve (solo se
  /// puede tener un viaje a la vez).
  VoidCallback? _accionPrincipal(Rol rol) {
    switch (rol) {
      case Rol.remitente:
        return () => abrirNuevaEncomienda(context, ref);
      case Rol.viajero:
        final sinViaje = switch (ref.watch(miViajeProvider)) {
          AsyncData(:final value) => value == null,
          _ => false,
        };
        return sinViaje
            ? () => context.push(ViajeroRoutes.registrarViaje)
            : null;
    }
  }
}
