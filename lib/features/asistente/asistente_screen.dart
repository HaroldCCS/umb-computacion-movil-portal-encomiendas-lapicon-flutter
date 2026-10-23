import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tema.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../chat/widgets/burbuja_mensaje.dart';
import '../chat/widgets/compositor_mensaje.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import 'asistente_controller.dart';

/// Sugerencias iniciales según el rol.
List<String> sugerenciasAsistente(Rol? rol) => switch (rol) {
  Rol.viajero => const [
    '¿Cómo registro mi vuelo?',
    '¿Qué no puedo llevar en mi maleta?',
    '¿Cómo tomo una encomienda?',
  ],
  _ => const [
    '¿Cómo publico una encomienda?',
    'Quiero enviar algo de Bogota a Miami',
    '¿Cómo elijo un viajero confiable?',
  ],
};

/// Chat con el asistente de IA (`POST /api/chatbot`). Hoy el backend
/// responde 500: el error se muestra en la propia burbuja con "Reintentar".
class AsistenteScreen extends ConsumerWidget {
  const AsistenteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final estado = ref.watch(asistenteProvider);
    final notifier = ref.read(asistenteProvider.notifier);
    final rol = ref.watch(sessionProvider).rol;
    // La lista va invertida para que lo más reciente quede abajo.
    final items = <Widget>[
      if (estado.escribiendo) const _Escribiendo(),
      for (final m in estado.mensajes.reversed)
        _Burbuja(
          mensaje: m,
          onReintentar: m.error ? () => notifier.reintentar(m) : null,
        ),
    ];

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: CupertinoNavigationBar(
        backgroundColor: c.fondo.withValues(alpha: .92),
        border: Border(bottom: BorderSide(color: c.separador, width: .5)),
        middle: Text(
          'Asistente',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: c.texto,
          ),
        ),
        trailing: BotonIcono(
          icono: Icons.refresh_rounded,
          etiqueta: 'Nueva conversación',
          borde: false,
          onTap: estado.esNueva ? null : notifier.reiniciar,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: estado.esNueva && !estado.escribiendo
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Vacio(
                        titulo: '¿En qué te ayudo?',
                        icono: Icons.support_agent,
                        texto:
                            'Pregúntame cómo publicar, viajar o qué puedes '
                            'llevar.',
                        accion: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in sugerenciasAsistente(rol))
                              Boton(
                                s,
                                chico: true,
                                ancho: false,
                                variante: VarianteBoton.tonal,
                                onTap: () => notifier.enviar(s),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    children: items,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'Respuestas generadas por IA; verifica la información '
              'importante.',
              style: TextStyle(fontSize: 13, color: c.texto2),
              textAlign: TextAlign.center,
            ),
          ),
          CompositorMensaje(
            pista: 'Escribe tu pregunta…',
            enviando: estado.escribiendo,
            onEnviar: (texto) async {
              notifier.enviar(texto);
              return true;
            },
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, this.onReintentar});

  final MensajeAsistente mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final propio = mensaje.autor == AutorMensaje.usuario;
    final (fondo, texto) = mensaje.error
        ? (c.peligroSuave, c.peligro)
        : (propio ? (c.marcaSolido, c.sobreMarca) : (c.superficie, c.texto));

    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Semantics(
          label: propio ? 'Tú' : 'Asistente',
          liveRegion: !propio,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: formaBurbuja(propia: propio),
              border: propio || mensaje.error || c.conSombra
                  ? null
                  : Border.all(color: c.separador),
              boxShadow: propio || mensaje.error ? null : c.sombraTarjeta,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensaje.texto,
                  style: TextStyle(fontSize: 17, height: 1.35, color: texto),
                ),
                if (onReintentar != null) ...[
                  const SizedBox(height: 8),
                  Boton(
                    'Reintentar',
                    icono: Icons.refresh_rounded,
                    chico: true,
                    ancho: false,
                    variante: VarianteBoton.secundario,
                    onTap: onReintentar,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: 'El asistente está escribiendo',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.marca,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Escribiendo…',
                style: TextStyle(fontSize: 15, color: c.texto2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
