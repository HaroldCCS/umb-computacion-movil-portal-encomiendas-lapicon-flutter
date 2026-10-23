import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/insignia.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/viaje.dart';
import '../catalogo/ciudad_field.dart';
import 'envios_screen.dart';
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

  Future<void> _refrescar(String ciudad) async {
    ref.invalidate(viajerosPorOrigenProvider(ciudad));
    try {
      await ref.read(viajerosPorOrigenProvider(ciudad).future);
    } on Object {
      // El error se muestra en la propia pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final buscada = _buscada;
    return Pantalla(
      titulo: 'Buscar viajeros',
      textoAtras: 'Inicio',
      subtitulo: 'Mira quién sale de tu ciudad y cómo lo califican.',
      alActualizar: buscada == null ? null : () => _refrescar(buscada),
      cabecera: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Medidas.margen),
        child: CiudadField(
          label: '¿Desde dónde envías?',
          controller: _ciudad,
          hint: 'Elige la ciudad de origen',
          icon: Icons.trip_origin,
          onChanged: (c) => setState(() => _buscada = c),
        ),
      ),
      hijos: buscada == null
          ? const [
              Vacio(
                titulo: 'Encuentra quién viaja',
                icono: Icons.travel_explore_outlined,
                texto:
                    'Elige tu ciudad para ver los viajeros que salen de allí '
                    'y sus calificaciones.',
              ),
            ]
          : _resultados(buscada),
    );
  }

  List<Widget> _resultados(String ciudad) {
    return switch (ref.watch(viajerosPorOrigenProvider(ciudad))) {
      AsyncData(value: final viajes) when viajes.isEmpty => [
        Vacio(
          titulo: 'Nadie viaja desde $ciudad por ahora',
          icono: Icons.flight_takeoff,
          texto:
              'Publica tu encomienda igual: los viajeros que registren un '
              'vuelo desde $ciudad la verán.',
          accion: Boton(
            'Publicar encomienda',
            icono: Icons.add_rounded,
            onTap: () => abrirNuevaEncomienda(context, ref),
          ),
        ),
      ],
      AsyncData(value: final viajes) => [
        for (final v in viajes) _ViajeroCard(viaje: v),
      ],
      AsyncError(:final error) => [
        ErrorCarga(
          mensaje: error is AppException
              ? error.message
              : 'No pudimos buscar viajeros.',
          alReintentar: () => ref.invalidate(viajerosPorOrigenProvider(ciudad)),
        ),
      ],
      _ => [const EsqueletoLista(cantidad: 2, alto: 200)],
    };
  }
}

/// Viajero con su calificación arriba y el pase de su vuelo debajo.
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
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: TrustRow(uid: uid, nombre: viaje.viajeroNombre),
          ),
        RouteTicket(
          origen: viaje.ciudadOrigen,
          destino: viaje.ciudadDestino,
          compact: true,
          accent: context.c.viajero,
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
          trailing: Insignia.viaje(viaje.estado),
        ),
      ],
    );
  }
}
