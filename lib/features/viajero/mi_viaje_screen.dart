import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/grupo.dart';
import '../../core/widgets/insignia.dart';
import '../../core/widgets/monto.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/tarjeta_accion.dart';
import '../../core/widgets/tarjeta_hero.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/rol.dart';
import '../../data/models/viaje.dart';
import '../../providers.dart';
import '../calificaciones/calificaciones_providers.dart';
import '../home/home_providers.dart';
import 'viajero_logic.dart';
import 'viajero_providers.dart';
import 'viajero_routes.dart';
import 'widgets/viajero_widgets.dart';

/// Pestaña "Mi viaje" (docs/08 §8.4): tarjeta principal con el viaje activo,
/// avisos de lo que falta por hacer, mis entregas e historial.
class MiViajeScreen extends ConsumerWidget {
  const MiViajeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miViaje = ref.watch(miViajeProvider);

    Future<void> refrescar() async {
      refrescarViajero(ref);
      try {
        await ref.read(miViajeProvider.future);
      } on Object {
        // El error se muestra en la propia pantalla.
      }
    }

    return Pantalla(
      titulo: 'Mi viaje',
      conBarraPestanas: true,
      alActualizar: refrescar,
      accion: BotonIcono(
        icono: Icons.support_agent,
        etiqueta: 'Asistente',
        borde: false,
        onTap: () => context.push(Routes.asistente),
      ),
      hijos: switch (miViaje) {
        AsyncData(value: final viaje?) => _conViaje(context, ref, viaje),
        AsyncData() => [
          Vacio(
            titulo: 'Aún no tienes un viaje activo',
            icono: Icons.flight_takeoff,
            texto:
                'Registra tu vuelo para ver encomiendas de tu ruta y ganar '
                'llevándolas.',
            accion: Boton(
              'Registrar viaje',
              icono: Icons.flight_takeoff,
              onTap: () => context.push(ViajeroRoutes.registrarViaje),
            ),
          ),
          const _Historial(),
        ],
        AsyncError(:final error) => [
          ErrorCarga(
            mensaje: error is AppException
                ? error.message
                : 'No pudimos cargar tu viaje.',
            alReintentar: () => ref.invalidate(miViajeProvider),
          ),
        ],
        _ => [const EsqueletoLista(primero: 220, cantidad: 2, alto: 150)],
      },
    );
  }

  List<Widget> _conViaje(BuildContext context, WidgetRef ref, Viaje viaje) {
    final uid = ref.watch(sessionProvider).user?.uid;
    final verificado = switch (ref.watch(viajeroLocalStoreProvider)) {
      AsyncData(:final value) =>
        uid != null &&
            value.vueloVerificado(uid, viaje.numeroVuelo, viaje.fechaViaje),
      _ => false,
    };
    final entregas = ref.watch(misEntregasProvider);
    final lista = entregas.value ?? const <Encomienda>[];
    final pendientes = porEntregar(lista);
    final porCalificar = porCalificarViajero(lista, calificadasDe(ref));
    final ganancias = gananciasPorMoneda(lista);

    final vuelo = viaje.numeroVuelo.isEmpty ? 'Vuelo' : viaje.numeroVuelo;
    final nota = '$vuelo · ${Fmt.fecha(viaje.fechaViaje)}';
    // Si el vuelo no se pudo verificar, la tarjeta lo dice siempre.
    final etiquetaVuelo = verificado ? 'Vuelo verificado' : 'Sin verificar';

    return [
      TarjetaHero(
        rol: Rol.viajero,
        titulo: 'Tu viaje',
        principal: Text(
          '${viaje.ciudadOrigen} → ${viaje.ciudadDestino}',
          maxLines: 2,
          style: const TextStyle(fontSize: 30, height: 1.1),
        ),
        nota: nota,
        semantica:
            'Tu viaje de ${viaje.ciudadOrigen} a ${viaje.ciudadDestino}. '
            '$nota. $etiquetaVuelo. Llevas ${pendientes.length} por entregar.',
        insignia: EtiquetaVidrio(
          etiquetaVuelo,
          icono: verificado ? Icons.verified : Icons.help_outline_rounded,
        ),
        subTarjetas: [
          SubTarjetaVidrio(
            etiqueta: 'Por entregar',
            icono: Icons.luggage,
            valor: Text(entregas.hasValue ? '${pendientes.length}' : '…'),
          ),
          SubTarjetaVidrio(
            etiqueta: 'Te pagan',
            icono: Icons.payments_outlined,
            tono: const Color(0xFFFDE68A),
            valor: switch (ganancias.length) {
              _ when !entregas.hasValue => const Text('…'),
              0 => const Text('Aún nada'),
              1 => Monto(ganancias.values.first, moneda: ganancias.keys.first),
              _ => Text('${ganancias.length} monedas'),
            },
          ),
        ],
      ),
      if (pendientes.isNotEmpty)
        TarjetaAccion(
          icono: Icons.luggage,
          titulo: pendientes.length == 1
              ? 'Tienes una encomienda por entregar'
              : 'Tienes ${pendientes.length} encomiendas por entregar',
          texto: pendientes.length == 1
              ? 'Va a ${pendientes.first.ciudadDestino}. Márcala como '
                    'entregada al dejarla.'
              : 'Márcalas como entregadas cuando las dejes en destino.',
          onTap: () => abrirEncomiendaViajero(
            context,
            pendientes.first,
            accion: AccionPendiente.entregar,
          ),
        ),
      for (final e in porCalificar.take(2))
        TarjetaAccion(
          titulo: 'Entregaste la encomienda a ${e.ciudadDestino}',
          texto:
              'Califica a ${e.remitenteNombre ?? 'quien te la confió'}: tu '
              'opinión ayuda a otros viajeros.',
          onTap: () => abrirEncomiendaViajero(
            context,
            e,
            accion: AccionPendiente.calificar,
          ),
        ),
      _MisEntregas(entregas: entregas),
      const _Historial(),
    ];
  }
}

/// Abre el detalle de una encomienda del viajero, con [accion] resaltada si
/// se llega desde un aviso.
void abrirEncomiendaViajero(
  BuildContext context,
  Encomienda e, {
  AccionPendiente? accion,
}) => context.push(
  accion?.en(ViajeroRoutes.encomienda) ?? ViajeroRoutes.encomienda,
  extra: e,
);

class _MisEntregas extends ConsumerWidget {
  const _MisEntregas({required this.entregas});

  final AsyncValue<List<Encomienda>> entregas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Mis entregas', style: context.t.titleLarge),
        ),
        const SizedBox(height: 12),
        switch (entregas) {
          AsyncData(:final value) when value.isEmpty => Aviso(
            'Aún no has tomado encomiendas. En Explorar ves las de tu ruta.',
            accion: Boton(
              'Ir a Explorar',
              chico: true,
              ancho: false,
              variante: VarianteBoton.tonal,
              onTap: () =>
                  ref.read(pestanaInicioProvider.notifier).ir(Pestanas.segunda),
            ),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (var i = 0; i < value.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                EncomiendaTicket(
                  encomienda: value[i],
                  onTap: () => abrirEncomiendaViajero(context, value[i]),
                ),
              ],
            ],
          ),
          AsyncError(:final error) => Aviso(
            error is AppException
                ? error.message
                : 'No pudimos cargar tus entregas.',
            tipo: TipoAviso.error,
            accion: Boton(
              'Reintentar',
              chico: true,
              ancho: false,
              variante: VarianteBoton.secundario,
              onTap: () => ref.invalidate(misEntregasProvider),
            ),
          ),
          _ => const EsqueletoLista(cantidad: 1, alto: 150),
        },
      ],
    );
  }
}

/// Últimos viajes en lista agrupada. Si no hay ninguno, no se muestra.
class _Historial extends ConsumerWidget {
  const _Historial();

  static const maximo = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(historialViajesProvider);
    return switch (historial) {
      AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
      AsyncData(:final value) => Grupo(
        titulo: 'Historial de viajes',
        pie: value.length > maximo
            ? 'Se muestran tus últimos $maximo viajes.'
            : null,
        hijos: [for (final v in value.take(maximo)) _FilaViaje(viaje: v)],
      ),
      AsyncError() => Aviso(
        'No pudimos cargar el historial de viajes.',
        tipo: TipoAviso.error,
        accion: Boton(
          'Reintentar',
          chico: true,
          ancho: false,
          variante: VarianteBoton.secundario,
          onTap: () => ref.invalidate(historialViajesProvider),
        ),
      ),
      _ => const Esqueleto(alto: 120, radio: Medidas.radioTarjeta),
    };
  }
}

class _FilaViaje extends StatelessWidget {
  const _FilaViaje({required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final vuelo = viaje.numeroVuelo.isEmpty ? 'Vuelo' : viaje.numeroVuelo;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(Icons.flight, color: c.viajero)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${viaje.ciudadOrigen} → ${viaje.ciudadDestino}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.texto,
                    ),
                  ),
                  Text(
                    '$vuelo · ${Fmt.fecha(viaje.fechaViaje)}',
                    style: TextStyle(fontSize: 13, color: c.texto2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Insignia.viaje(viaje.estado),
          ],
        ),
      ),
    );
  }
}
