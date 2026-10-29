import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/accion_resaltada.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/grupo.dart';
import '../../core/widgets/hoja.dart';
import '../../core/widgets/monto.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/toast.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/calificaciones_providers.dart';
import 'envios_logic.dart';
import 'remitente_providers.dart';
import 'widgets/encomienda_ticket.dart';
import 'widgets/status_timeline.dart';
import 'widgets/trust_row.dart';

/// Detalle de una encomienda del remitente (patrón maestro-detalle). La
/// acción principal va fija abajo, así siempre está a la vista; si se llega
/// desde un aviso (`accion`), se explica encima del botón.
/// Al cerrar devuelve `true` si la encomienda cambió (para refrescar la lista).
class EncomiendaDetalleScreen extends ConsumerStatefulWidget {
  const EncomiendaDetalleScreen({
    super.key,
    required this.encomienda,
    this.accion,
  });

  final Encomienda encomienda;

  /// Acción a la que se llegó desde un aviso (se resalta al abrir).
  final AccionPendiente? accion;

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
  String? _error;

  @override
  void initState() {
    super.initState();
    // Abrir el detalle cuenta como haber visto el aviso de "te la tomaron".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(sessionProvider).user?.uid;
      if (mounted && uid != null && _e.estado == EstadoEncomienda.tomada) {
        ref.read(estadosVistosProvider(uid).notifier).marcarVistas([_e]);
      }
    });
  }

  /// Retirar es irreversible: se confirma escribiendo RETIRAR.
  Future<void> _retirar() async {
    final ok = await confirmarConHoja(
      context,
      titulo: '¿Retirar la encomienda?',
      mensaje:
          'Los viajeros dejarán de verla y quedará en tu historial como '
          'vencida. Esta acción no se puede deshacer.',
      confirmarTexto: 'Sí, retirarla',
      destructivo: true,
      palabra: 'RETIRAR',
    );
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final actualizada = await ref
          .read(encomiendaRepositoryProvider)
          // El backend no tiene "cancelada": retirarla la deja vencida.
          .cambiarEstado(_e.id, EstadoEncomienda.vencida);
      if (!mounted) return;
      setState(() {
        _e = (actualizada != null && actualizada.id.isNotEmpty)
            ? actualizada
            : conEstado(_e, EstadoEncomienda.vencida);
        _cambio = true;
      });
      mostrarToast(context, 'Encomienda retirada');
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
    final c = context.c;
    final viajero = _e.viajeroUid;
    final calificada = _calificada || calificadasDe(ref).contains(_e.id);
    final acciones = _acciones(calificada: calificada);

    // El gesto/botón "atrás" del sistema también devuelve si hubo cambios.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_cambio);
      },
      child: Pantalla(
        titulo: 'Tu envío',
        textoAtras: 'Envíos',
        pie: acciones.isEmpty
            ? null
            : AccionResaltada(
                activa:
                    widget.accion == AccionPendiente.calificar &&
                    _e.estado.finalizada &&
                    !calificada,
                aviso:
                    'Califica a ${_e.viajeroNombre ?? 'quien la llevó'}: '
                    'tu opinión ayuda a otros remitentes.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Aviso(_error!, tipo: TipoAviso.error),
                      const SizedBox(height: 12),
                    ],
                    ...acciones,
                  ],
                ),
              ),
        hijos: [
          EncomiendaTicket(encomienda: _e),
          // Con viajero: lo primero que se ve es quién la lleva (docs/11 §2G).
          if (viajero != null && _e.estado == EstadoEncomienda.tomada)
            Grupo(
              titulo: 'Quién la lleva',
              hijos: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrustRow(uid: viajero, nombre: _e.viajeroNombre),
                      const SizedBox(height: 12),
                      Boton(
                        'Escribirle',
                        icono: Icons.chat_bubble_outline,
                        chico: true,
                        variante: VarianteBoton.tonal,
                        onTap: _abrirChat,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Grupo(
            titulo: 'Estado',
            hijos: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StatusTimeline(
                  estado: _e.estado,
                  calificada: calificada,
                ),
              ),
            ],
            pie: switch (_e.estado) {
              EstadoEncomienda.disponible =>
                'Cuando un viajero de tu ruta la tome, te avisaremos aquí '
                    'y podrán coordinar por chat.',
              EstadoEncomienda.tomada =>
                '${_e.viajeroNombre ?? 'Un viajero'} aceptó llevarla. '
                    'Coordinen por chat dónde y cuándo se la entregas.',
              _ => null,
            },
          ),
          Grupo(
            titulo: 'Detalles',
            hijos: [
              Fila(
                'Pago al viajero',
                Monto(_e.valor, moneda: _e.moneda),
                extra: 'Lo que ofreciste por llevarla.',
              ),
              Fila('Publicada', Text(Fmt.fecha(_e.creadaEn))),
              if (_e.fechaVencimiento != null)
                Fila(
                  'Fecha límite',
                  Text(Fmt.fecha(_e.fechaVencimiento)),
                  extra: 'Después deja de verse.',
                ),
            ],
          ),
          Grupo(
            titulo: 'Qué envías',
            hijos: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _e.observaciones.isEmpty
                      ? 'Sin descripción'
                      : _e.observaciones,
                  style: TextStyle(fontSize: 17, height: 1.4, color: c.texto),
                ),
              ),
            ],
          ),
          if (viajero != null && _e.estado != EstadoEncomienda.tomada)
            Grupo(
              titulo: 'Quién la llevó',
              hijos: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TrustRow(uid: viajero, nombre: _e.viajeroNombre),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _acciones({required bool calificada}) {
    final c = context.c;
    switch (_e.estado) {
      case EstadoEncomienda.disponible:
        return [
          Boton(
            'Retirar encomienda',
            icono: Icons.remove_circle_outline,
            variante: VarianteBoton.peligro,
            textoCargando: 'Retirando…',
            cargando: _loading,
            onTap: _retirar,
          ),
        ];
      case EstadoEncomienda.tomada:
        return [
          Boton(
            'Abrir chat',
            icono: Icons.chat_bubble_outline,
            onTap: _e.viajeroUid == null ? null : _abrirChat,
          ),
        ];
      case EstadoEncomienda.entregada || EstadoEncomienda.recibida:
        return [
          if (calificada)
            Text(
              '¡Gracias por calificar! Tu opinión ayuda a otros remitentes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.texto2),
            )
          else
            Boton(
              'Calificar al viajero',
              icono: Icons.star_outline_rounded,
              onTap: _e.viajeroUid == null ? null : _calificar,
            ),
          if (_e.viajeroUid != null) ...[
            const SizedBox(height: 8),
            Boton(
              'Ver chat',
              icono: Icons.chat_bubble_outline,
              variante: VarianteBoton.secundario,
              onTap: _abrirChat,
            ),
          ],
        ];
      case EstadoEncomienda.vencida:
      case EstadoEncomienda.desconocido:
        return const [];
    }
  }
}
