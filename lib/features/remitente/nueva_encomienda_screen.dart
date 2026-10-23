import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/toast.dart';
import '../../providers.dart';
import '../catalogo/ciudad_field.dart';
import 'envios_logic.dart';

/// Publicar una encomienda → `POST /api/encomiendas` (docs/07 §7.6).
/// Secciones Ruta · Pago · Detalles y vista previa del pase. Al terminar
/// hace `pop(true)` para que la lista se refresque.
class NuevaEncomiendaScreen extends ConsumerStatefulWidget {
  const NuevaEncomiendaScreen({super.key});

  @override
  ConsumerState<NuevaEncomiendaScreen> createState() =>
      _NuevaEncomiendaScreenState();
}

class _NuevaEncomiendaScreenState extends ConsumerState<NuevaEncomiendaScreen> {
  static const monedas = ['USD', 'COP', 'EUR'];

  final _formKey = GlobalKey<FormState>();
  final _origen = TextEditingController();
  final _destino = TextEditingController();
  final _valor = TextEditingController();
  final _observaciones = TextEditingController();
  String _moneda = 'USD';
  bool _loading = false;
  bool _intentoEnviar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // La vista previa se actualiza con cada cambio.
    for (final c in [_origen, _destino, _valor]) {
      c.addListener(_refrescar);
    }
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_origen, _destino, _valor, _observaciones]) {
      c.dispose();
    }
    super.dispose();
  }

  void _intercambiar() {
    final o = _origen.text;
    _origen.text = _destino.text;
    _destino.text = o;
  }

  /// El backend fija el vencimiento: un mes después de publicarla.
  DateTime get _vence {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month + 1, hoy.day);
  }

  Future<void> _publicar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _intentoEnviar = true;
      _error = null;
    });
    final formOk = _formKey.currentState?.validate() ?? false;
    final rutaError = validarRuta(_origen.text, _destino.text);
    if (!formOk || rutaError != null) {
      setState(
        () => _error = rutaError ?? 'Revisa los campos marcados en rojo.',
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(encomiendaRepositoryProvider)
          .crear(
            ciudadOrigen: _origen.text.trim(),
            ciudadDestino: _destino.text.trim(),
            observaciones: _observaciones.text.trim(),
            moneda: _moneda,
            valor: parseValor(_valor.text)!,
          );
      if (!mounted) return;
      mostrarToast(context, 'Encomienda publicada');
      context.pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rutaError = _intentoEnviar
        ? validarRuta(_origen.text, _destino.text)
        : null;
    final valor = parseValor(_valor.text);

    return Form(
      key: _formKey,
      child: Pantalla(
        titulo: 'Nueva encomienda',
        subtitulo: 'Cuéntale al viajero qué lleva, a dónde y cuánto pagas.',
        hijos: [
          // Un solo bloque: así todos los campos existen al validar.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Seccion('Ruta'),
              CiudadField(
                label: 'Origen',
                controller: _origen,
                hint: '¿Desde dónde envías?',
                icon: Icons.trip_origin,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: BotonIcono(
                  icono: Icons.swap_vert,
                  etiqueta: 'Intercambiar origen y destino',
                  borde: false,
                  onTap: _intercambiar,
                ),
              ),
              CiudadField(
                label: 'Destino',
                controller: _destino,
                hint: '¿A dónde va?',
                icon: Icons.place_outlined,
              ),
              if (rutaError != null) ...[
                const SizedBox(height: 8),
                Aviso(rutaError, tipo: TipoAviso.error),
              ],
              const SizedBox(height: 28),
              const _Seccion('Pago al viajero'),
              CampoMonto(
                controlador: _valor,
                moneda: _moneda,
                etiqueta: '¿Cuánto le pagas por llevarla?',
                validador: validarValor,
              ),
              const SizedBox(height: 12),
              const EtiquetaCampo('Moneda'),
              Chips<String>(
                relleno: EdgeInsets.zero,
                opciones: [for (final m in monedas) (m, m, null)],
                valor: _moneda,
                onCambio: (m) => setState(() => _moneda = m),
              ),
              const SizedBox(height: 28),
              const _Seccion('Detalles'),
              Campo(
                etiqueta: 'Qué envías',
                controlador: _observaciones,
                pista: 'Ej. Un libro y dos camisetas',
                ayuda:
                    'Sé claro: el viajero debe saber qué lleva en su maleta.',
                capitalizacion: TextCapitalization.sentences,
                accionTeclado: TextInputAction.done,
                maxLength: 200,
                lineas: 3,
                validador: validarObservaciones,
                checkValido: false,
              ),
              const SizedBox(height: 12),
              Aviso('Estará publicada un mes: hasta el ${Fmt.fecha(_vence)}.'),
              const SizedBox(height: 28),
              const _Seccion('Así la verán los viajeros'),
              ExcludeSemantics(
                child: RouteTicket(
                  origen: _origen.text.isEmpty ? '¿Origen?' : _origen.text,
                  destino: _destino.text.isEmpty ? '¿Destino?' : _destino.text,
                  accent: c.atencion,
                  details: [
                    TicketDetail(
                      label: 'Te pagan',
                      value: valor == null || valor <= 0
                          ? '—'
                          : Fmt.dinero(valor, _moneda),
                    ),
                    TicketDetail(
                      label: 'Vence',
                      value: Fmt.fecha(_vence, corta: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Aviso(_error!, tipo: TipoAviso.error),
                const SizedBox(height: 12),
              ],
              Boton(
                'Publicar encomienda',
                textoCargando: 'Publicando…',
                cargando: _loading,
                onTap: _publicar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Título de sección del formulario ("Ruta", "Pago al viajero").
class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      header: true,
      child: Text(titulo, style: context.t.titleLarge),
    ),
  );
}
