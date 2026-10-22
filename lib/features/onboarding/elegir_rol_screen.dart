import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback_views.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../session/session_controller.dart';

/// Paso 2 de 2 (o cambio de rol desde el perfil).
class ElegirRolScreen extends ConsumerStatefulWidget {
  const ElegirRolScreen({super.key});

  @override
  ConsumerState<ElegirRolScreen> createState() => _ElegirRolScreenState();
}

class _ElegirRolScreenState extends ConsumerState<ElegirRolScreen> {
  Rol? _seleccionado;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _seleccionado = ref.read(sessionProvider).rol;
  }

  Future<void> _continuar() async {
    final rol = _seleccionado;
    if (rol == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider).elegirRol(rol);
      if (mounted) context.go('/inicio');
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final cambiando = session.status == SessionStatus.listo;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: cambiando,
        title: Text(cambiando ? 'Cambiar de rol' : 'Elige cómo empezar'),
      ),
      body: FormPage(
        children: [
          if (!cambiando) ...[
            const StepIndicator(step: 2, total: 2),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            '¿Qué quieres hacer hoy${session.perfil != null ? ', ${session.perfil!.nombre}' : ''}?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final rol in Rol.values) ...[
            RoleCard(
              rol: rol,
              selected: _seleccionado == rol,
              onTap: () => setState(() => _seleccionado = rol),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Puedes cambiar de rol cuando quieras desde tu perfil.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Continuar',
            loading: _loading,
            onPressed: _seleccionado == null ? null : _continuar,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta grande seleccionable para elegir el rol.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.rol,
    required this.selected,
    required this.onTap,
  });

  final Rol rol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = rol.accent(theme.brightness);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rol.icon,
                      color: rol.onAccent(theme.brightness),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rol.titulo, style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          rol.descripcion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
