import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/theme/vocabulario.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/encabezado_app.dart';
import '../../core/widgets/entrada.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/mosaico.dart';
import '../../core/widgets/tarjeta_accion.dart';
import '../../core/widgets/tarjeta_hero.dart';
import '../../data/models/encomienda.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/calificaciones_providers.dart';
import '../home/home_providers.dart';
import 'envios_logic.dart';
import 'envios_screen.dart';
import 'remitente_providers.dart';
import 'remitente_routes.dart';
import 'widgets/aviso_tomada.dart';

/// Pestaña "Inicio" del remitente (docs/08 §8.4): tarjeta principal con los
/// envíos activos, avisos que llevan directo a la acción pendiente y
/// "Vista rápida".
class InicioRemitenteScreen extends ConsumerWidget {
  const InicioRemitenteScreen({super.key});

  /// Como mucho dos avisos sueltos; si hay más, uno que los resume.
  static const maxAvisos = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final session = ref.watch(sessionProvider);
    final envios = ref.watch(misEncomiendasProvider);
    escucharEstadosVistos(ref);

    Future<void> refrescar() async {
      ref.invalidate(misEncomiendasProvider);
      try {
        await ref.read(misEncomiendasProvider.future);
      } on Object {
        // El error se muestra en la propia pantalla.
      }
    }

    final contenido = switch (envios) {
      AsyncData(:final value) => _contenido(
        context,
        ref,
        value,
        calificadasDe(ref),
      ),
      AsyncError(:final error) => [
        ErrorCarga(
          mensaje: error is AppException
              ? error.message
              : 'No pudimos cargar tus envíos.',
          alReintentar: () => ref.invalidate(misEncomiendasProvider),
        ),
      ],
      _ => [const EsqueletoLista(primero: 190, cantidad: 2, alto: 120)],
    };

    return Scaffold(
      backgroundColor: c.fondo,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: refrescar),
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: session,
              builder: (context, _) => EncabezadoApp(
                usuario: session.perfil?.nombreCompleto ?? '',
                rol: Rol.remitente,
                alTocarAvatar: () => ref
                    .read(pestanaInicioProvider.notifier)
                    .ir(Pestanas.perfil),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Medidas.margen,
              12,
              Medidas.margen,
              Medidas.bajoBarra(context),
            ),
            sliver: SliverList.separated(
              itemCount: contenido.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: Medidas.bloque),
              itemBuilder: (_, i) => Entrada(indice: i, child: contenido[i]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenido(
    BuildContext context,
    WidgetRef ref,
    List<Encomienda> lista,
    Set<String> calificadas,
  ) {
    final r = ResumenEnvios.de(lista, calificadas);
    final vocabulario = Vocabulario.de(Rol.remitente);

    void irAEnvios(PestanaEnvios pestana) {
      ref.read(pestanaEnviosProvider.notifier).ir(pestana);
      ref.read(pestanaInicioProvider.notifier).ir(Pestanas.segunda);
    }

    void calificar(Encomienda e) =>
        abrirDetalleEnvio(context, ref, e, accion: AccionPendiente.calificar);

    final nuevas = nuevasTomadasDe(ref);
    return [
      // Arriba de todo: un viajero tomó una encomienda (docs/11 §2G).
      if (nuevas.isNotEmpty) const AvisosTomadas(),
      // Sin ningún envío, la tarjeta en cero no aporta: basta la invitación.
      if (lista.isNotEmpty)
        TarjetaHero(
          rol: Rol.remitente,
          titulo: vocabulario.tituloHero,
          principal: Text('${r.activas}'),
          nota: r.nota,
          semantica: '${vocabulario.tituloHero}: ${r.activas}. ${r.nota}',
          onTap: () => irAEnvios(PestanaEnvios.activas),
          subTarjetas: [
            SubTarjetaVidrio(
              etiqueta: 'Tomadas',
              icono: Icons.how_to_reg_outlined,
              valor: Text('${r.tomadas}'),
            ),
            SubTarjetaVidrio(
              etiqueta: 'Disponibles',
              icono: Icons.schedule,
              tono: TonosVidrio.ambar,
              valor: Text('${r.disponibles}'),
            ),
          ],
        ),
      // Avisos que empujan a la acción: cada uno abre el detalle con
      // "Calificar" resaltado.
      if (r.porCalificar.length <= maxAvisos)
        for (final e in r.porCalificar)
          TarjetaAccion(
            titulo: 'Tu encomienda a ${e.ciudadDestino} ya fue entregada',
            texto:
                'Califica a ${e.viajeroNombre ?? 'quien la llevó'}: tu '
                'opinión ayuda a otros remitentes.',
            onTap: () => calificar(e),
          )
      else
        TarjetaAccion(
          titulo: 'Tienes ${r.porCalificar.length} entregas por calificar',
          texto: 'Califica a quienes llevaron tus encomiendas.',
          onTap: () => irAEnvios(PestanaEnvios.entregadas),
        ),
      if (lista.isEmpty)
        Vacio(
          titulo: 'Aún no has enviado nada',
          icono: Icons.inventory_2_outlined,
          texto: 'Publica tu primera encomienda y encuentra quién la lleve.',
          accion: Boton(
            'Publicar encomienda',
            icono: Icons.add_rounded,
            onTap: () => abrirNuevaEncomienda(context, ref),
          ),
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Vista rápida', style: context.t.titleLarge),
          ),
          const SizedBox(height: 12),
          GrillaMosaicos([
            if (r.porCalificar.isNotEmpty)
              Mosaico(
                icono: Icons.star_outline_rounded,
                color: Pastel.ambar,
                etiqueta: 'Por calificar',
                valor: Text('${r.porCalificar.length}'),
                onTap: () => r.porCalificar.length == 1
                    ? calificar(r.porCalificar.first)
                    : irAEnvios(PestanaEnvios.entregadas),
              ),
            Mosaico(
              icono: Icons.check_circle_outline,
              color: Pastel.verde,
              etiqueta: 'Entregadas',
              valor: Text('${r.entregadas}'),
              onTap: () => irAEnvios(PestanaEnvios.entregadas),
            ),
            Mosaico(
              icono: Icons.travel_explore,
              color: Pastel.azul,
              etiqueta: 'Buscar viajeros',
              valor: const Text('Por ciudad'),
              onTap: () => context.push(RemitenteRoutes.viajeros),
            ),
            Mosaico(
              icono: Icons.support_agent,
              color: Pastel.violeta,
              etiqueta: 'Asistente',
              valor: const Text('Pregúntale'),
              onTap: () => context.push(Routes.asistente),
            ),
          ]),
        ],
      ),
    ];
  }
}
