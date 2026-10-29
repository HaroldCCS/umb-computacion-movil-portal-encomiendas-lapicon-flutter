import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/viaje.dart';
import '../catalogo/ciudad_field.dart';
import 'envios_screen.dart';
import 'remitente_providers.dart';
import 'widgets/trust_row.dart';

/// "Buscar viajeros" (desde Vista rápida del Inicio): quién viaja por la ruta
/// completa, con nombre y calificación (`GET /api/viajes/disponibles`,
/// docs/11 §2C).
class BuscarViajerosScreen extends ConsumerStatefulWidget {
  const BuscarViajerosScreen({super.key});

  @override
  ConsumerState<BuscarViajerosScreen> createState() =>
      _BuscarViajerosScreenState();
}

class _BuscarViajerosScreenState extends ConsumerState<BuscarViajerosScreen> {
  final _origen = TextEditingController();
  final _destino = TextEditingController();

  @override
  void dispose() {
    _origen.dispose();
    _destino.dispose();
    super.dispose();
  }

  ({String origen, String destino})? get _ruta =>
      _origen.text.isEmpty || _destino.text.isEmpty
      ? null
      : (origen: _origen.text, destino: _destino.text);

  Future<void> _refrescar(({String origen, String destino}) ruta) async {
    ref.invalidate(viajerosEnRutaProvider(ruta));
    try {
      await ref.read(viajerosEnRutaProvider(ruta).future);
    } on Object {
      // El error se muestra en la propia pantalla.
    }
  }

  void _intercambiar() {
    final o = _origen.text;
    setState(() {
      _origen.text = _destino.text;
      _destino.text = o;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ruta = _ruta;
    return Pantalla(
      titulo: 'Buscar viajeros',
      textoAtras: 'Inicio',
      subtitulo: 'Mira quién viaja por tu ruta y cómo lo califican.',
      alActualizar: ruta == null ? null : () => _refrescar(ruta),
      cabecera: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Medidas.margen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CiudadField(
              label: '¿Desde dónde envías?',
              controller: _origen,
              hint: 'Elige la ciudad de origen',
              icon: Icons.trip_origin,
              onChanged: (_) => setState(() {}),
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
              label: '¿A dónde?',
              controller: _destino,
              hint: 'Elige la ciudad de destino',
              icon: Icons.location_on_outlined,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      hijos: ruta == null
          ? const [
              Vacio(
                titulo: 'Encuentra quién viaja',
                icono: Icons.travel_explore_outlined,
                texto:
                    'Elige de dónde a dónde envías para ver los viajeros de '
                    'esa ruta y sus calificaciones.',
              ),
            ]
          : _resultados(ruta),
    );
  }

  List<Widget> _resultados(({String origen, String destino}) ruta) {
    return switch (ref.watch(viajerosEnRutaProvider(ruta))) {
      AsyncData(value: final viajes) when viajes.isEmpty => [
        Vacio(
          titulo: 'Nadie viaja ${ruta.origen} → ${ruta.destino} por ahora',
          icono: Icons.flight_takeoff,
          texto:
              'Publica tu encomienda igual: los viajeros que registren un '
              'vuelo en esa ruta la verán.',
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
          alReintentar: () => ref.invalidate(viajerosEnRutaProvider(ruta)),
        ),
      ],
      _ => [const EsqueletoLista(cantidad: 2, alto: 200)],
    };
  }
}

/// Viajero con su nombre y calificación arriba y el pase de su viaje debajo
/// (`viajes/disponibles` no trae el número de vuelo).
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
              label: 'Viaja el',
              value: Fmt.fecha(viaje.fechaViaje, corta: true),
            ),
          ],
        ),
      ],
    );
  }
}
