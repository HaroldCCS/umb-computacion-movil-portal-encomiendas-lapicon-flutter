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
import '../../core/widgets/insignia.dart';
import '../../core/widgets/monto.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/toast.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/estado.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/calificaciones_providers.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';
import 'widgets/viajero_widgets.dart';

/// Detalle de una encomienda desde el punto de vista del viajero:
/// tomarla, abrir el chat, marcarla como entregada y calificar al remitente.
class EncomiendaViajeroScreen extends ConsumerStatefulWidget {
  const EncomiendaViajeroScreen({
    super.key,
    required this.encomienda,
    this.accion,
  });

  final Encomienda encomienda;

  /// Acción a la que se llegó desde un aviso (se resalta al abrir).
  final AccionPendiente? accion;

  @override
  ConsumerState<EncomiendaViajeroScreen> createState() =>
      _EncomiendaViajeroScreenState();
}

class _EncomiendaViajeroScreenState
    extends ConsumerState<EncomiendaViajeroScreen> {
  late Encomienda _e = widget.encomienda;
  bool _loading = false;
  bool _calificada = false;
  String? _error;

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
    final ok = await confirmarToma(context, _e);
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

  /// Irreversible (cierra el chat): se confirma escribiendo ENTREGAR.
  Future<void> _marcarEntregada() async {
    final ok = await confirmarConHoja(
      context,
      titulo: '¿Ya la entregaste?',
      mensaje:
          'Hazlo solo cuando el paquete ya esté en manos del destinatario. '
          'La entrega queda registrada, el chat se cierra y podrán '
          'calificarse.',
      confirmarTexto: 'Sí, ya la entregué',
      palabra: 'ENTREGAR',
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
          ? conservarNombres(respuesta, _e)
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
      setState(() => _calificada = true);
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mensaje = await accion();
      refrescarViajero(ref);
      if (mounted) mostrarToast(context, mensaje);
    } on AppException catch (e) {
      // El error va junto a la acción, no en un aviso genérico.
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final uid = ref.watch(sessionProvider).user?.uid;
    final mia = tomadaPorMi(_e, uid, _idsLocales());
    final sinRemitente = _e.remitenteUid == null;
    final calificada = _calificada || calificadasDe(ref).contains(_e.id);
    final resaltar = switch (widget.accion) {
      AccionPendiente.entregar => mia && _e.estado == EstadoEncomienda.tomada,
      AccionPendiente.calificar =>
        mia && _e.estado.finalizada && !calificada && !sinRemitente,
      null => false,
    };

    return Pantalla(
      titulo: 'Encomienda',
      pie: AccionResaltada(
        activa: resaltar,
        aviso: widget.accion == AccionPendiente.entregar
            ? 'Cuando la dejes en destino, márcala como entregada: así el '
                  'remitente sabe que llegó.'
            : 'Califica a ${_e.remitenteNombre ?? 'quien te la confió'}: tu '
                  'opinión ayuda a otros viajeros.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Aviso(_error!, tipo: TipoAviso.error),
              const SizedBox(height: 12),
            ],
            ..._acciones(
              mia: mia,
              sinRemitente: sinRemitente,
              calificada: calificada,
            ),
          ],
        ),
      ),
      hijos: [
        // Fijo, no un toast: que no quede duda de que la tomó y de qué sigue
        // (docs/11 §2G).
        if (mia && _e.estado == EstadoEncomienda.tomada)
          Aviso(
            '1. Escríbele a ${_e.remitenteNombre ?? 'quien la publicó'} para '
            'recibir el paquete.\n'
            '2. Llévalo en tu viaje${switch (ref.watch(miViajeProvider).value?.numeroVuelo) {
              final v? when v.isNotEmpty => ' $v',
              _ => '',
            }}.\n'
            '3. Al entregarlo, márcala como entregada.',
            titulo: 'Tú llevas esta encomienda',
            tipo: TipoAviso.exito,
          ),
        RouteTicket(
          origen: _e.ciudadOrigen,
          destino: _e.ciudadDestino,
          accent: c.viajero,
          details: [
            if (_e.fechaVencimiento != null)
              TicketDetail(
                label: 'Vence',
                value: Fmt.fecha(_e.fechaVencimiento),
              ),
          ],
          trailing: Insignia.encomienda(
            _e.estado,
            rol: mia ? Rol.viajero : Rol.remitente,
          ),
        ),
        Grupo(
          titulo: 'Lo que te pagan',
          hijos: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Monto(
                _e.valor,
                moneda: _e.moneda,
                estilo: context.t.displaySmall?.copyWith(color: c.texto),
              ),
            ),
          ],
        ),
        Grupo(
          titulo: 'Qué llevas',
          hijos: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _e.observaciones.isEmpty
                    ? 'El remitente no agregó detalles.'
                    : _e.observaciones,
                style: TextStyle(fontSize: 17, height: 1.4, color: c.texto),
              ),
            ),
          ],
        ),
        Grupo(
          titulo: 'Remitente',
          hijos: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: sinRemitente
                  // Solo pasa con encomiendas guardadas antes de usar
                  // /buscar, que trae el uid.
                  ? Text(
                      _e.remitenteNombre == null
                          ? 'Remitente'
                          : 'La publicó ${_e.remitenteNombre}.',
                      style: TextStyle(fontSize: 15, color: c.texto2),
                    )
                  : PersonaTrustRow(
                      uid: _e.remitenteUid!,
                      nombre: _e.remitenteNombre,
                      rolLabel: 'Remitente',
                    ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _acciones({
    required bool mia,
    required bool sinRemitente,
    required bool calificada,
  }) {
    Widget info(String texto) => Aviso(texto);

    switch (_e.estado) {
      case EstadoEncomienda.disponible:
      case EstadoEncomienda.desconocido:
        if (mia) return [info('Ya tomaste esta encomienda.')];
        return [
          Boton(
            'Tomar encomienda',
            icono: Icons.luggage,
            textoCargando: 'Tomando…',
            cargando: _loading,
            onTap: _tomar,
          ),
        ];
      case EstadoEncomienda.tomada:
        if (!mia) return [info('Otra persona ya tomó esta encomienda.')];
        // Lo siguiente es coordinar con el remitente; entregar es lo último.
        return [
          Boton(
            'Escribir al remitente',
            icono: Icons.chat_bubble_outline,
            onTap: sinRemitente || _loading ? null : _abrirChat,
          ),
          const SizedBox(height: 8),
          Boton(
            'Marcar como entregada',
            icono: Icons.check_circle_outline,
            variante: VarianteBoton.secundario,
            textoCargando: 'Guardando…',
            cargando: _loading,
            onTap: _marcarEntregada,
          ),
        ];
      case EstadoEncomienda.entregada || EstadoEncomienda.recibida:
        if (!mia) return [info('Esta encomienda ya fue entregada.')];
        return [
          if (calificada)
            info('¡Gracias por calificar! Tu opinión ayuda a otros viajeros.')
          else
            Boton(
              'Calificar al remitente',
              icono: Icons.star_outline_rounded,
              onTap: sinRemitente ? null : _calificar,
            ),
          const SizedBox(height: 8),
          Boton(
            'Ver chat',
            icono: Icons.chat_bubble_outline,
            variante: VarianteBoton.secundario,
            onTap: sinRemitente ? null : _abrirChat,
          ),
        ];
      case EstadoEncomienda.vencida:
        return [info('Esta encomienda ya no está publicada.')];
    }
  }
}
