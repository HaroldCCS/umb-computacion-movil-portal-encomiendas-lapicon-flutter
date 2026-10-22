import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import 'envios_logic.dart';
import 'widgets/encomienda_ticket.dart';
import 'widgets/status_timeline.dart';
import 'widgets/trust_row.dart';

/// Detalle de una encomienda del remitente (patrón maestro-detalle).
/// Al cerrar devuelve `true` si la encomienda cambió (para refrescar la lista).
class EncomiendaDetalleScreen extends ConsumerStatefulWidget {
  const EncomiendaDetalleScreen({super.key, required this.encomienda});

  final Encomienda encomienda;

  @override
  ConsumerState<EncomiendaDetalleScreen> createState() =>
      _EncomiendaDetalleScreenState();
}

class _EncomiendaDetalleScreenState
    extends ConsumerState<EncomiendaDetalleScreen> {
  late Encomienda _e = widget.encomienda;
  bool _cambio = false;
  bool _calificada = false;
  bool _loading = false;

  Future<void> _cancelar() async {
    final ok = await confirmar(
      context,
      titulo: '¿Cancelar la encomienda?',
      mensaje:
          'Los viajeros dejarán de verla. Esta acción no se puede deshacer.',
      confirmarLabel: 'Sí, cancelar',
      destructivo: true,
    );
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final actualizada = await ref
          .read(encomiendaRepositoryProvider)
          .cambiarEstado(_e.id, EstadoEncomienda.cancelada);
      if (!mounted) return;
      setState(() {
        _e = (actualizada != null && actualizada.id.isNotEmpty)
            ? actualizada
            : conEstado(_e, EstadoEncomienda.cancelada);
        _cambio = true;
      });
      showAppSnackBar(context, 'Encomienda cancelada');
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirChat() {
    final viajero = _e.viajeroUid;
    if (viajero == null) return;
    context.push(
      Routes.chat,
      extra: ChatArgs(
        otroUid: viajero,
        otroNombre: _e.viajeroNombre,
        encomienda: _e,
      ),
    );
  }

  Future<void> _calificar() async {
    final viajero = _e.viajeroUid;
    if (viajero == null) return;
    final ok = await context.push<bool>(
      Routes.calificar,
      extra: CalificarArgs(
        usuarioDestino: viajero,
        rolDestino: Rol.viajero,
        nombreDestino: _e.viajeroNombre,
        encomienda: _e,
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _calificada = true;
        _cambio = true;
      });
      ref.invalidate(resumenCalificacionesProvider(viajero));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viajero = _e.viajeroUid;

    // El gesto/botón "atrás" del sistema también devuelve si hubo cambios.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_cambio);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del envío'),
          leading: BackButton(onPressed: () => context.pop(_cambio)),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  EncomiendaTicket(encomienda: _e),
                  const SizedBox(height: AppSpacing.lg),
                  _Tarjeta(
                    titulo: 'ESTADO',
                    child: StatusTimeline(
                      estado: _e.estado,
                      calificada: _calificada,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Tarjeta(
                    titulo: 'DETALLES',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Dato(
                          icon: Icons.payments_outlined,
                          label: 'Pago al viajero',
                          value: Fmt.dinero(_e.valor, _e.moneda),
                        ),
                        _Dato(
                          icon: Icons.notes,
                          label: 'Qué envías',
                          value: _e.observaciones.isEmpty
                              ? 'Sin descripción'
                              : _e.observaciones,
                        ),
                        _Dato(
                          icon: Icons.event_available_outlined,
                          label: 'Publicada',
                          value: Fmt.fecha(_e.creadaEn),
                        ),
                        if (_e.fechaVencimiento != null)
                          _Dato(
                            icon: Icons.event_busy_outlined,
                            label: 'Fecha límite',
                            value: Fmt.fecha(_e.fechaVencimiento),
                          ),
                      ],
                    ),
                  ),
                  if (viajero != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Tarjeta(
                      titulo: 'QUIÉN LA LLEVA',
                      child: TrustRow(uid: viajero, nombre: _e.viajeroNombre),
                    ),
                  ],
                  if (_e.estado == EstadoEncomienda.disponible) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cuando un viajero de tu ruta la tome, te avisaremos '
                      'aquí y podrán coordinar por chat.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ..._acciones(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _acciones(ThemeData theme) {
    switch (_e.estado) {
      case EstadoEncomienda.disponible:
        return [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: _loading ? null : _cancelar,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar encomienda'),
          ),
        ];
      case EstadoEncomienda.tomada:
        return [
          PrimaryButton(
            label: 'Abrir chat',
            icon: Icons.chat_bubble_outline,
            onPressed: _e.viajeroUid == null ? null : _abrirChat,
          ),
        ];
      case EstadoEncomienda.entregada:
        return [
          if (_calificada)
            Text(
              '¡Gracias por calificar! Tu opinión ayuda a otros remitentes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            )
          else
            PrimaryButton(
              label: 'Calificar al viajero',
              icon: Icons.star_outline,
              onPressed: _e.viajeroUid == null ? null : _calificar,
            ),
          if (_e.viajeroUid != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _abrirChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ver chat'),
            ),
          ],
        ];
      case EstadoEncomienda.vencida:
      case EstadoEncomienda.cancelada:
      case EstadoEncomienda.desconocido:
        return const [];
    }
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
