import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';
import 'widgets/viajero_widgets.dart';

/// Detalle de una encomienda desde el punto de vista del viajero:
/// tomarla, abrir el chat, marcarla como entregada y calificar al remitente.
class EncomiendaViajeroScreen extends ConsumerStatefulWidget {
  const EncomiendaViajeroScreen({super.key, required this.encomienda});

  final Encomienda encomienda;

  @override
  ConsumerState<EncomiendaViajeroScreen> createState() =>
      _EncomiendaViajeroScreenState();
}

class _EncomiendaViajeroScreenState
    extends ConsumerState<EncomiendaViajeroScreen> {
  late Encomienda _e = widget.encomienda;
  bool _loading = false;

  String? get _uid => ref.read(sessionProvider).user?.uid;

  Set<String> _idsLocales() {
    final uid = _uid;
    return switch (ref.watch(viajeroLocalStoreProvider)) {
      AsyncData(:final value) when uid != null => value.idsEntregas(uid),
      _ => const {},
    };
  }

  Future<void> _guardarLocal(Encomienda e) async {
    final uid = _uid;
    if (uid == null) return;
    final store = await ref.read(viajeroLocalStoreProvider.future);
    await store.guardarEntrega(uid, e);
    ref.invalidate(viajeroLocalStoreProvider);
  }

  Future<void> _tomar() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => ConfirmarTomaSheet(encomienda: _e),
    );
    if (ok != true || !mounted) return;
    await _accion(() async {
      final respuesta = await ref
          .read(encomiendaRepositoryProvider)
          .tomar(_e.id);
      final actualizada = (respuesta != null && respuesta.id.isNotEmpty)
          ? respuesta
          : conEstado(_e, EstadoEncomienda.tomada, viajeroUid: _uid);
      // Aseguramos que quede marcada como mía aunque el backend no lo diga.
      final mia = actualizada.viajeroUid == null
          ? conEstado(actualizada, actualizada.estado, viajeroUid: _uid)
          : actualizada;
      await _guardarLocal(mia);
      if (mounted) setState(() => _e = mia);
      return '¡Listo! La encomienda es tuya. Coordina la entrega por chat.';
    });
  }

  Future<void> _marcarEntregada() async {
    final ok = await confirmar(
      context,
      titulo: '¿Marcar como entregada?',
      mensaje:
          'Hazlo solo cuando el paquete ya esté en manos del destinatario.',
      confirmarLabel: 'Sí, ya la entregué',
    );
    if (!ok || !mounted) return;
    await _accion(() async {
      final respuesta = await ref
          .read(encomiendaRepositoryProvider)
          .cambiarEstado(_e.id, EstadoEncomienda.entregada);
      final actualizada =
          (respuesta != null &&
              respuesta.id.isNotEmpty &&
              respuesta.estado == EstadoEncomienda.entregada)
          ? respuesta
          : conEstado(_e, EstadoEncomienda.entregada);
      await _guardarLocal(actualizada);
      if (mounted) setState(() => _e = actualizada);
      return 'Entrega registrada. Ahora califica al remitente.';
    });
  }

  Future<void> _calificar() async {
    final remitente = _e.remitenteUid;
    if (remitente == null) return;
    final ok = await context.push<bool>(
      Routes.calificar,
      extra: CalificarArgs(
        usuarioDestino: remitente,
        rolDestino: Rol.remitente,
        nombreDestino: _e.remitenteNombre,
        encomienda: _e,
      ),
    );
    if (ok == true && mounted) {
      showAppSnackBar(context, '¡Gracias por calificar!');
    }
  }

  void _abrirChat() {
    final remitente = _e.remitenteUid;
    if (remitente == null) return;
    context.push(
      Routes.chat,
      extra: ChatArgs(
        otroUid: remitente,
        otroNombre: _e.remitenteNombre,
        encomienda: _e,
      ),
    );
  }

  /// Ejecuta una acción con carga, errores amables y refresco de listas.
  Future<void> _accion(Future<String> Function() accion) async {
    setState(() => _loading = true);
    try {
      final mensaje = await accion();
      refrescarViajero(ref);
      if (mounted) showAppSnackBar(context, mensaje);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(sessionProvider).user?.uid;
    final mia = tomadaPorMi(_e, uid, _idsLocales());
    final sinRemitente = _e.remitenteUid == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Encomienda')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            RouteTicket(
              origen: _e.ciudadOrigen,
              destino: _e.ciudadDestino,
              accent: Rol.viajero.accent(theme.brightness),
              details: [
                if (_e.fechaVencimiento != null)
                  TicketDetail(
                    label: 'Vence',
                    value: Fmt.fecha(_e.fechaVencimiento),
                  ),
              ],
              trailing: StatusChip.encomienda(_e.estado),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Te pagan ${Fmt.dinero(_e.valor, _e.moneda)}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TE PAGAN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Fmt.dinero(_e.valor, _e.moneda),
                    style: theme.textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            const SeccionHeader('Qué llevas'),
            Text(
              _e.observaciones.isEmpty
                  ? 'El remitente no agregó detalles.'
                  : _e.observaciones,
              style: theme.textTheme.bodyLarge,
            ),
            const SeccionHeader('Remitente'),
            if (sinRemitente)
              Text(
                'No sabemos quién publicó esta encomienda, así que el chat y '
                'la calificación no están disponibles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              PersonaTrustRow(
                uid: _e.remitenteUid!,
                nombre: _e.remitenteNombre,
                rolLabel: 'Remitente',
              ),
            const SizedBox(height: AppSpacing.xl),
            ..._acciones(mia: mia, sinRemitente: sinRemitente),
          ],
        ),
      ),
    );
  }

  List<Widget> _acciones({required bool mia, required bool sinRemitente}) {
    final theme = Theme.of(context);
    Widget info(String texto) => Text(
      texto,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );

    switch (_e.estado) {
      case EstadoEncomienda.disponible:
      case EstadoEncomienda.desconocido:
        if (mia) return [info('Ya tomaste esta encomienda.')];
        return [
          PrimaryButton(
            label: 'Tomar encomienda',
            icon: Icons.luggage,
            loading: _loading,
            onPressed: _tomar,
          ),
        ];
      case EstadoEncomienda.tomada:
        if (!mia) return [info('Otra persona ya tomó esta encomienda.')];
        return [
          PrimaryButton(
            label: 'Marcar como entregada',
            icon: Icons.check_circle_outline,
            loading: _loading,
            onPressed: _marcarEntregada,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: sinRemitente || _loading ? null : _abrirChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Abrir chat con el remitente'),
          ),
        ];
      case EstadoEncomienda.entregada || EstadoEncomienda.recibida:
        if (!mia) return [info('Esta encomienda ya fue entregada.')];
        return [
          PrimaryButton(
            label: 'Calificar al remitente',
            icon: Icons.star_outline,
            onPressed: sinRemitente ? null : _calificar,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: sinRemitente ? null : _abrirChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ver chat'),
          ),
        ];
      case EstadoEncomienda.vencida:
        return [info('Esta encomienda ya no está publicada.')];
    }
  }
}
