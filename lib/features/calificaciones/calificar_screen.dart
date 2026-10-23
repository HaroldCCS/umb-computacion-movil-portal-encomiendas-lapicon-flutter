import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/theme/vocabulario.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/route_ticket.dart';
import '../../core/widgets/toast.dart';
import '../../providers.dart';
import 'calificaciones_providers.dart';
import 'rating_input.dart';

/// Formulario para calificar (Práctica 6) → `POST /api/ratings`.
/// Al terminar hace `context.pop(true)`.
class CalificarScreen extends ConsumerStatefulWidget {
  const CalificarScreen({super.key, required this.args});

  final CalificarArgs? args;

  @override
  ConsumerState<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends ConsumerState<CalificarScreen> {
  static const _maxComentario = 300;

  final _comentario = TextEditingController();
  final _sugerencias = <String>{};
  int _puntaje = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _cambiarPuntaje(int puntaje) {
    setState(() {
      // Las sugerencias positivas y negativas no se mezclan.
      if ((puntaje >= 4) != (_puntaje >= 4)) _sugerencias.clear();
      _puntaje = puntaje;
    });
  }

  Future<void> _enviar(CalificarArgs args) async {
    if (_puntaje == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(calificacionesRepositoryProvider)
          .calificar(
            usuarioDestino: args.usuarioDestino,
            rolDestino: args.rolDestino,
            calificacion: _puntaje,
            comentario: componerComentario(
              _sugerencias,
              _comentario.text,
              maxLength: _maxComentario,
            ),
            encomiendaId: args.encomienda?.id,
          );
      ref.invalidate(resumenCalificacionesProvider(args.usuarioDestino));
      final uid = ref.read(sessionProvider).user?.uid;
      final id = args.encomienda?.id;
      if (uid != null && id != null && id.isNotEmpty) {
        await ref.read(calificadasProvider(uid).notifier).marcar(id);
      }
      if (!mounted) return;
      mostrarToast(context, '¡Gracias por calificar!');
      context.pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return const Pantalla(
        titulo: 'Calificar',
        hijos: [
          Vacio(
            titulo: 'No pudimos abrir la calificación',
            icono: Icons.star_outline_rounded,
            texto: 'Vuelve al detalle de la encomienda e inténtalo de nuevo.',
          ),
        ],
      );
    }

    final c = context.c;
    final nombre = (args.nombreDestino?.trim().isNotEmpty ?? false)
        ? args.nombreDestino!.trim()
        : Vocabulario.de(args.rolDestino.opuesto).laContraparte;
    final encomienda = args.encomienda;

    return Pantalla(
      titulo: 'Calificar',
      hijos: [
        // Un solo bloque: estrellas, sugerencias, comentario y botón.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Avatar(nombre, tam: 72)),
            const SizedBox(height: 16),
            Text(
              '¿Cómo te fue con $nombre?',
              style: context.t.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu calificación ayuda a otras personas a confiar en la '
              'comunidad.',
              style: TextStyle(fontSize: 15, color: c.texto2),
              textAlign: TextAlign.center,
            ),
            if (encomienda != null) ...[
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: RouteTicket(
                  origen: encomienda.ciudadOrigen,
                  destino: encomienda.ciudadDestino,
                  compact: true,
                ),
              ),
            ],
            const SizedBox(height: 24),
            RatingInput(value: _puntaje, onChanged: _cambiarPuntaje),
            if (_puntaje > 0) ...[
              const SizedBox(height: 16),
              ChipsMultiples(
                opciones: sugerenciasPara(_puntaje),
                seleccionadas: _sugerencias,
                onCambio: (s) => setState(() {
                  if (!_sugerencias.remove(s)) _sugerencias.add(s);
                }),
              ),
            ],
            const SizedBox(height: 24),
            Campo(
              etiqueta: 'Comentario (opcional)',
              controlador: _comentario,
              pista: 'Cuéntanos cómo fue la entrega',
              capitalizacion: TextCapitalization.sentences,
              accionTeclado: TextInputAction.newline,
              maxLength: _maxComentario,
              lineas: 3,
              checkValido: false,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Aviso(_error!, tipo: TipoAviso.error),
              const SizedBox(height: 12),
            ],
            Boton(
              'Enviar calificación',
              textoCargando: 'Enviando…',
              cargando: _enviando,
              onTap: _puntaje == 0 ? null : () => _enviar(args),
            ),
            if (_puntaje == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Elige de 1 a 5 estrellas para poder enviar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.texto2),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
