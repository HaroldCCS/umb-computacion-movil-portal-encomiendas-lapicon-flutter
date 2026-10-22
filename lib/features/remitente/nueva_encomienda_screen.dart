import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/route_ticket.dart';
import '../../providers.dart';
import '../catalogo/ciudad_field.dart';
import 'envios_logic.dart';

/// Publicar una encomienda → `POST /api/encomiendas` (docs/07 §7.6).
/// Al terminar hace `pop(true)` para que la lista se refresque.
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
    setState(() => _intentoEnviar = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    final rutaError = validarRuta(_origen.text, _destino.text);
    if (!formOk || rutaError != null) {
      if (rutaError != null) showAppSnackBar(context, rutaError, error: true);
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
      showAppSnackBar(context, 'Encomienda publicada');
      context.pop(true);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rutaError = _intentoEnviar
        ? validarRuta(_origen.text, _destino.text)
        : null;
    final valor = parseValor(_valor.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva encomienda')),
      body: Form(
        key: _formKey,
        child: FormPage(
          children: [
            const _Seccion('RUTA'),
            CiudadField(
              label: 'Origen',
              controller: _origen,
              hint: '¿Desde dónde envías?',
              icon: Icons.trip_origin,
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
              label: 'Destino',
              controller: _destino,
              hint: '¿A dónde va?',
              icon: Icons.place_outlined,
            ),
            if (rutaError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs, left: 2),
                child: Text(
                  rutaError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const _Seccion('PAGO AL VIAJERO'),
            AppTextField(
              label: 'Valor',
              controller: _valor,
              hint: 'Ej. 10',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: validarValor,
              prefixIcon: Icons.payments_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: 'Moneda',
              child: SegmentedButton<String>(
                segments: [
                  for (final m in monedas)
                    ButtonSegment(value: m, label: Text(m)),
                ],
                selected: {_moneda},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _moneda = s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Seccion('DETALLES'),
            AppTextField(
              label: 'Qué envías',
              controller: _observaciones,
              hint: 'Ej. Un libro y dos camisetas',
              helper: 'Sé claro: el viajero debe saber qué lleva en su maleta.',
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 200,
              validator: validarObservaciones,
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Estará publicada un mes: hasta el ${Fmt.fecha(_vence)}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Seccion('ASÍ LA VERÁN LOS VIAJEROS'),
            ExcludeSemantics(
              child: RouteTicket(
                origen: _origen.text.isEmpty ? '¿Origen?' : _origen.text,
                destino: _destino.text.isEmpty ? '¿Destino?' : _destino.text,
                accent: theme.brightness == Brightness.dark
                    ? AppColors.amberDark
                    : AppColors.estadoTomada,
                details: [
                  TicketDetail(
                    label: 'Valor',
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
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Publicar encomienda',
              loading: _loading,
              onPressed: _publicar,
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          titulo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
