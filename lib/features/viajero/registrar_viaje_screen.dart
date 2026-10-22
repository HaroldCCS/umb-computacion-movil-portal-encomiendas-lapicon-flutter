import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers.dart';
import '../catalogo/ciudad_field.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';
import 'widgets/viajero_widgets.dart';

enum _Verificacion {
  ninguna,
  verificando,
  verificado,
  noEncontrado,
  noDisponible,
}

/// Registrar un viaje (`POST /api/viajes`) con verificación del vuelo
/// contra AeroDataBox (`GET /api/vuelos/:numero/:fecha`).
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
  _Verificacion _verificacion = _Verificacion.ninguna;
  List<String> _datosVuelo = const [];

  @override
  void dispose() {
    _vuelo.dispose();
    _fechaTexto.dispose();
    _origen.dispose();
    _destino.dispose();
    super.dispose();
  }

  void _resetVerificacion() {
    if (_verificacion != _Verificacion.ninguna) {
      setState(() {
        _verificacion = _Verificacion.ninguna;
        _datosVuelo = const [];
      });
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha del vuelo',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fecha = elegida;
      _fechaTexto.text = Fmt.fecha(elegida);
    });
    _resetVerificacion();
  }

  void _intercambiar() {
    final o = _origen.text;
    setState(() {
      _origen.text = _destino.text;
      _destino.text = o;
    });
  }

  Future<void> _verificar() async {
    FocusScope.of(context).unfocus();
    final errorVuelo = validarNumeroVuelo(_vuelo.text);
    final fecha = _fecha;
    if (errorVuelo != null || fecha == null) {
      showAppSnackBar(
        context,
        errorVuelo ?? 'Elige la fecha del vuelo para verificarlo.',
        error: true,
      );
      return;
    }
    setState(() => _verificacion = _Verificacion.verificando);
    try {
      final json = await ref
          .read(viajeRepositoryProvider)
          .validarVuelo(normalizarVuelo(_vuelo.text), fecha);
      if (!mounted) return;
      setState(() {
        _verificacion = _Verificacion.verificado;
        _datosVuelo = resumenVuelo(json);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _verificacion = e.isNotFound
            ? _Verificacion.noEncontrado
            : _Verificacion.noDisponible,
      );
    } on AppException {
      if (mounted) setState(() => _verificacion = _Verificacion.noDisponible);
    }
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_origen.text == _destino.text) {
      showAppSnackBar(
        context,
        'El origen y el destino deben ser ciudades distintas.',
        error: true,
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
      final uid = ref.read(sessionProvider).user?.uid;
      if (uid != null && _verificacion == _Verificacion.verificado) {
        final store = await ref.read(viajeroLocalStoreProvider.future);
        await store.marcarVueloVerificado(uid, numero, fecha);
        ref.invalidate(viajeroLocalStoreProvider);
      }
      refrescarViajero(ref);
      if (!mounted) return;
      showAppSnackBar(context, 'Viaje registrado. ¡Buen vuelo!');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isBusinessRule) {
        await _mostrarReglaNegocio(e.message);
      } else {
        showAppSnackBar(context, e.message, error: true);
      }
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarReglaNegocio(String mensaje) async {
    final verViaje = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No pudimos registrar el viaje'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ver mi viaje'),
          ),
        ],
      ),
    );
    if (verViaje == true && mounted) {
      refrescarViajero(ref);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar viaje')),
      body: Form(
        key: _formKey,
        child: FormPage(
          children: [
            Text('Cuéntanos de tu vuelo', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Lo verificamos con la aerolínea para que los remitentes '
              'confíen en ti.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Número de vuelo',
              controller: _vuelo,
              hint: 'AV24',
              helper:
                  'Código de la aerolínea y número, como aparece en tu '
                  'pasabordo.',
              prefixIcon: Icons.confirmation_number_outlined,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 ]')),
                const _MayusculasFormatter(),
                LengthLimitingTextInputFormatter(8),
              ],
              validator: validarNumeroVuelo,
              onChanged: (_) => _resetVerificacion(),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Fecha del vuelo',
              controller: _fechaTexto,
              hint: 'Elige la fecha',
              readOnly: true,
              onTap: _elegirFecha,
              prefixIcon: Icons.event_outlined,
              showValidCheck: false,
              suffix: const Icon(Icons.expand_more),
              validator: (v) => Validators.requerido(v, 'La fecha'),
            ),
            const SizedBox(height: AppSpacing.md),
            CiudadField(
              label: 'Ciudad de origen',
              controller: _origen,
              icon: Icons.flight_takeoff,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Intercambiar origen y destino',
                icon: const Icon(Icons.swap_vert),
                onPressed: _intercambiar,
              ),
            ),
            CiudadField(
              label: 'Ciudad de destino',
              controller: _destino,
              icon: Icons.flight_land,
            ),
            const SizedBox(height: AppSpacing.lg),
            _VerificacionCard(
              estado: _verificacion,
              datos: _datosVuelo,
              onVerificar: _loading ? null : _verificar,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Registrar viaje',
              icon: Icons.flight_takeoff,
              loading: _loading,
              onPressed: _verificacion == _Verificacion.verificando
                  ? null
                  : _registrar,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificacionCard extends StatelessWidget {
  const _VerificacionCard({
    required this.estado,
    required this.datos,
    required this.onVerificar,
  });

  final _Verificacion estado;
  final List<String> datos;
  final VoidCallback? onVerificar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget contenido = switch (estado) {
      _Verificacion.ninguna => OutlinedButton.icon(
        onPressed: onVerificar,
        icon: const Icon(Icons.verified_outlined),
        label: const Text('Verificar vuelo'),
      ),
      _Verificacion.verificando => const Row(
        children: [
          SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Verificando vuelo…')),
        ],
      ),
      _Verificacion.verificado => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VueloVerificadoBadge(),
          for (final d in datos)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(d, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
      _Verificacion.noEncontrado => _AvisoVerificacion(
        icon: Icons.search_off,
        texto:
            'No encontramos ese vuelo para esa fecha. Revisa el número y la '
            'fecha; si estás seguro, puedes registrarlo igual.',
        onVerificar: onVerificar,
      ),
      _Verificacion.noDisponible => _AvisoVerificacion(
        icon: Icons.cloud_off_outlined,
        texto:
            'Ahora no pudimos verificar el vuelo. Puedes registrarlo igual: '
            'el servidor también lo valida.',
        onVerificar: onVerificar,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(estado), child: contenido),
      ),
    );
  }
}

class _AvisoVerificacion extends StatelessWidget {
  const _AvisoVerificacion({
    required this.icon,
    required this.texto,
    required this.onVerificar,
  });

  final IconData icon;
  final String texto;
  final VoidCallback? onVerificar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.estadoTomada),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(texto, style: theme.textTheme.bodyMedium)),
            ],
          ),
          TextButton(
            onPressed: onVerificar,
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
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
