import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/presionable.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../session/session_controller.dart';

/// Paso 2 de 2 (o cambio de rol desde el perfil).
class ElegirRolScreen extends ConsumerStatefulWidget {
  const ElegirRolScreen({super.key});

  @override
  ConsumerState<ElegirRolScreen> createState() => _ElegirRolScreenState();
}

class _ElegirRolScreenState extends ConsumerState<ElegirRolScreen> {
  Rol? _seleccionado;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seleccionado = ref.read(sessionProvider).rol;
  }

  Future<void> _continuar() async {
    final rol = _seleccionado;
    if (rol == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider).elegirRol(rol);
      if (mounted) context.go(Routes.inicio);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = ref.watch(sessionProvider);
    final cambiando = session.status == SessionStatus.listo;
    final nombre = session.perfil?.nombre;

    return Pantalla(
      titulo: cambiando ? 'Cambiar de rol' : 'Elige cómo empezar',
      subtitulo:
          '¿Qué quieres hacer hoy${nombre != null && nombre.isNotEmpty ? ', $nombre' : ''}?',
      hijos: [
        if (!cambiando) const StepIndicator(step: 2, total: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final rol in Rol.values) ...[
              TarjetaRol(
                rol: rol,
                seleccionada: _seleccionado == rol,
                onTap: () => setState(() => _seleccionado = rol),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Text(
              'Puedes cambiar de rol cuando quieras desde tu perfil.',
              style: TextStyle(fontSize: 15, color: c.texto2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Aviso(_error!, tipo: TipoAviso.error),
              const SizedBox(height: 12),
            ],
            Boton(
              'Continuar',
              textoCargando: 'Guardando…',
              cargando: _loading,
              onTap: _seleccionado == null ? null : _continuar,
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta grande seleccionable para elegir el rol: ícono con el acento del
/// rol, título, beneficio y marca de selección (no solo color).
class TarjetaRol extends StatelessWidget {
  const TarjetaRol({
    super.key,
    required this.rol,
    required this.seleccionada,
    required this.onTap,
  });

  final Rol rol;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final acento = c.acento(rol);
    final animar = !MediaQuery.disableAnimationsOf(context);

    return Semantics(
      selected: seleccionada,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${rol.titulo}. ${rol.descripcion}',
      onTap: onTap,
      excludeSemantics: true,
      child: Presionable(
        onTap: onTap,
        escala: 0.98,
        child: AnimatedContainer(
          duration: animar ? const Duration(milliseconds: 200) : Duration.zero,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: seleccionada
                ? Color.alphaBlend(acento.withValues(alpha: 0.12), c.superficie)
                : c.superficie,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            border: Border.all(
              color: seleccionada ? acento : c.separador,
              width: seleccionada ? 2 : 1,
            ),
            boxShadow: seleccionada ? null : c.sombraTarjeta,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: acento,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(rol.icono, color: c.sobreAcento(rol), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rol.titulo,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: c.texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rol.descripcion,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: c.texto2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                seleccionada
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: seleccionada ? c.marca : c.texto3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
