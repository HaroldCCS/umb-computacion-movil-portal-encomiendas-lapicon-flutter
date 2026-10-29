import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/hoja.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/toast.dart';
import '../../providers.dart';
import '../catalogo/ciudad_field.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';

/// Registrar un viaje (`POST /api/viajes`). La consulta del vuelo
/// (`GET /api/vuelos/:numero/:fecha`) no se muestra: el servidor responde 500
/// (docs/11 §2H).
class RegistrarViajeScreen extends ConsumerStatefulWidget {
  const RegistrarViajeScreen({super.key});

  @override
  ConsumerState<RegistrarViajeScreen> createState() =>
      _RegistrarViajeScreenState();
}

class _RegistrarViajeScreenState extends ConsumerState<RegistrarViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vuelo = TextEditingController();
  final _fechaTexto = TextEditingController();
  final _origen = TextEditingController();
  final _destino = TextEditingController();
  DateTime? _fecha;
  bool _loading = false;

  /// Error al registrar, junto al botón.
  String? _error;

  @override
  void dispose() {
    _vuelo.dispose();
    _fechaTexto.dispose();
    _origen.dispose();
    _destino.dispose();
    super.dispose();
  }

  /// Selector de fecha estilo iOS en una hoja (docs/08 §8.8-4).
  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await mostrarHoja<DateTime>(
      context,
      titulo: 'Fecha del vuelo',
      contenido: _SelectorFecha(
        inicial: _fecha ?? hoy,
        minima: hoy,
        maxima: hoy.add(const Duration(days: 365)),
      ),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fecha = elegida;
      _fechaTexto.text = Fmt.fecha(elegida);
    });
  }

  void _intercambiar() {
    final o = _origen.text;
    setState(() {
      _origen.text = _destino.text;
      _destino.text = o;
    });
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _error = 'Revisa los campos marcados en rojo.');
      return;
    }
    if (_origen.text == _destino.text) {
      setState(
        () => _error = 'El origen y el destino deben ser ciudades distintas.',
      );
      return;
    }
    final fecha = _fecha!;
    final numero = normalizarVuelo(_vuelo.text);
    setState(() => _loading = true);
    try {
      await ref
          .read(viajeRepositoryProvider)
          .crear(
            numeroVuelo: numero,
            ciudadOrigen: _origen.text,
            ciudadDestino: _destino.text,
            fechaViaje: fecha,
          );
      refrescarViajero(ref);
      if (!mounted) return;
      mostrarToast(context, 'Viaje registrado. ¡Buen vuelo!');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isBusinessRule) {
        // El botón deja de cargar antes de abrir la hoja.
        setState(() => _loading = false);
        await _mostrarReglaNegocio(e.message);
      } else {
        setState(() => _error = e.message);
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Regla del backend (p. ej. "Ya tienes un viaje activo"): se explica en
  /// una hoja con el camino a seguir.
  Future<void> _mostrarReglaNegocio(String mensaje) async {
    final verViaje = await confirmarConHoja(
      context,
      titulo: 'No pudimos registrar el viaje',
      mensaje: mensaje,
      confirmarTexto: 'Ver mi viaje',
      cancelarTexto: 'Cerrar',
    );
    if (verViaje && mounted) {
      refrescarViajero(ref);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Pantalla(
        titulo: 'Registrar viaje',
        textoAtras: 'Mi viaje',
        subtitulo: 'Los remitentes de tu ruta verán tu vuelo y fecha.',
        hijos: [
          // Un solo bloque: así todos los campos existen al validar.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Campo(
                etiqueta: 'Número de vuelo',
                controlador: _vuelo,
                pista: 'AV24',
                ayuda:
                    'Código de la aerolínea y número, como aparece en tu '
                    'pasabordo.',
                icono: Icons.confirmation_number_outlined,
                capitalizacion: TextCapitalization.characters,
                formateadores: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 ]')),
                  const _MayusculasFormatter(),
                  LengthLimitingTextInputFormatter(8),
                ],
                validador: validarNumeroVuelo,
              ),
              const SizedBox(height: 16),
              Campo(
                etiqueta: 'Fecha del vuelo',
                controlador: _fechaTexto,
                pista: 'Elige la fecha',
                soloLectura: true,
                alTocar: _elegirFecha,
                icono: Icons.event_outlined,
                checkValido: false,
                sufijo: const Icon(Icons.expand_more),
                validador: (v) => Validators.requerido(v, 'La fecha'),
              ),
              const SizedBox(height: 16),
              CiudadField(
                label: 'Ciudad de origen',
                controller: _origen,
                icon: Icons.flight_takeoff,
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
                label: 'Ciudad de destino',
                controller: _destino,
                icon: Icons.flight_land,
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Aviso(_error!, tipo: TipoAviso.error),
                const SizedBox(height: 12),
              ],
              Boton(
                'Registrar viaje',
                icono: Icons.flight_takeoff,
                textoCargando: 'Registrando…',
                cargando: _loading,
                onTap: _registrar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contenido de la hoja de fecha: rueda de iOS y botón para confirmar.
class _SelectorFecha extends StatefulWidget {
  const _SelectorFecha({
    required this.inicial,
    required this.minima,
    required this.maxima,
  });

  final DateTime inicial;
  final DateTime minima;
  final DateTime maxima;

  @override
  State<_SelectorFecha> createState() => _SelectorFechaState();
}

class _SelectorFechaState extends State<_SelectorFecha> {
  late DateTime _fecha = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: widget.inicial,
            minimumDate: widget.minima,
            maximumDate: widget.maxima,
            onDateTimeChanged: (f) => _fecha = DateUtils.dateOnly(f),
          ),
        ),
        const SizedBox(height: 16),
        Boton(
          'Elegir esta fecha',
          onTap: () => Navigator.of(context).pop(_fecha),
        ),
      ],
    );
  }
}

/// Convierte a mayúsculas mientras se escribe ("av24" → "AV24").
class _MayusculasFormatter extends TextInputFormatter {
  const _MayusculasFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
