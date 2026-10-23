import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/viaje.dart';
import '../catalogo/ciudad_field.dart';
import 'remitente_providers.dart';
import 'widgets/trust_row.dart';

/// "Buscar viajeros" (desde Vista rápida del Inicio): quién viaja desde una
/// ciudad, con su calificación.
class BuscarViajerosScreen extends ConsumerStatefulWidget {
  const BuscarViajerosScreen({super.key});

  @override
  ConsumerState<BuscarViajerosScreen> createState() =>
      _BuscarViajerosScreenState();
}

class _BuscarViajerosScreenState extends ConsumerState<BuscarViajerosScreen> {
  final _ciudad = TextEditingController();
  String? _buscada;

  @override
  void dispose() {
    _ciudad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buscada = _buscada;
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar viajeros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: CiudadField(
              label: '¿Desde dónde envías?',
              controller: _ciudad,
              hint: 'Elige la ciudad de origen',
              icon: Icons.trip_origin,
              onChanged: (c) => setState(() => _buscada = c),
            ),
          ),
          Expanded(
            child: buscada == null
                ? const EmptyState(
                    icon: Icons.travel_explore_outlined,
                    title: 'Encuentra quién viaja',
                    message:
                        'Elige tu ciudad para ver los viajeros que salen de '
                        'allí y sus calificaciones.',
                  )
                : _Resultados(ciudad: buscada),
          ),
        ],
      ),
    );
  }
}

class _Resultados extends ConsumerWidget {
  const _Resultados({required this.ciudad});

  final String ciudad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(viajerosPorOrigenProvider(ciudad));
    return resultado.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Buscando viajeros'),
      ),
      error: (e, _) => ErrorView(
        message: e is AppException ? e.message : 'No pudimos buscar viajeros.',
        onRetry: () => ref.invalidate(viajerosPorOrigenProvider(ciudad)),
      ),
      data: (viajes) {
        if (viajes.isEmpty) {
          return EmptyState(
            icon: Icons.flight_takeoff,
            title: 'Nadie viaja desde $ciudad por ahora',
            message:
                'Publica tu encomienda igual: los viajeros que registren un '
                'vuelo desde $ciudad la verán.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(viajerosPorOrigenProvider(ciudad));
            try {
              await ref.read(viajerosPorOrigenProvider(ciudad).future);
            } on Object {
              // Se muestra en la vista de error.
            }
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: viajes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, i) => _ViajeroCard(viaje: viajes[i]),
          ),
        );
      },
    );
  }
}

class _ViajeroCard extends StatelessWidget {
  const _ViajeroCard({required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    final uid = viaje.viajeroUid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (uid != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: TrustRow(uid: uid, nombre: viaje.viajeroNombre),
          ),
        RouteTicket(
          origen: viaje.ciudadOrigen,
          destino: viaje.ciudadDestino,
          compact: true,
          details: [
            TicketDetail(
              label: 'Vuelo',
              value: viaje.numeroVuelo.isEmpty ? '—' : viaje.numeroVuelo,
            ),
            TicketDetail(
              label: 'Fecha',
              value: Fmt.fecha(viaje.fechaViaje, corta: true),
            ),
          ],
          trailing: StatusChip.viaje(viaje.estado),
        ),
      ],
    );
  }
}
