import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/route_ticket.dart';
import '../../data/models/rol.dart';
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
    setState(() => _enviando = true);
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
      showAppSnackBar(context, '¡Gracias por calificar!');
      context.pop(true);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calificar')),
        body: const EmptyState(
          icon: Icons.star_outline_rounded,
          title: 'No pudimos abrir la calificación',
          message: 'Vuelve al detalle de la encomienda e inténtalo de nuevo.',
        ),
      );
    }

    final theme = Theme.of(context);
    final nombre = (args.nombreDestino?.trim().isNotEmpty ?? false)
        ? args.nombreDestino!.trim()
        : (args.rolDestino == Rol.viajero ? 'el viajero' : 'el remitente');
    final encomienda = args.encomienda;

    return Scaffold(
      appBar: AppBar(title: const Text('Calificar')),
      body: FormPage(
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: args.rolDestino.accent(theme.brightness),
              child: Text(
                _iniciales(args.nombreDestino),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: args.rolDestino.onAccent(theme.brightness),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¿Cómo te fue con $nombre?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tu calificación ayuda a otras personas a confiar en la comunidad.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (encomienda != null) ...[
            const SizedBox(height: AppSpacing.lg),
            RouteTicket(
              origen: encomienda.ciudadOrigen,
              destino: encomienda.ciudadDestino,
              compact: true,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          RatingInput(value: _puntaje, onChanged: _cambiarPuntaje),
          if (_puntaje > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in sugerenciasPara(_puntaje))
                  FilterChip(
                    label: Text(s),
                    selected: _sugerencias.contains(s),
                    onSelected: (sel) => setState(
                      () => sel ? _sugerencias.add(s) : _sugerencias.remove(s),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Comentario (opcional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _comentario,
            maxLength: _maxComentario,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Cuéntanos cómo fue la entrega',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Enviar calificación',
            loading: _enviando,
            onPressed: _puntaje == 0 ? null : () => _enviar(args),
          ),
        ],
      ),
    );
  }

  static String _iniciales(String? nombre) {
    final partes = (nombre ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    if (partes.isEmpty) return '?';
    return partes
        .map((p) => String.fromCharCode(p.runes.first).toUpperCase())
        .join();
  }
}
