import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'toast.dart';

/// Estado vacío: ícono en círculo + título + texto + acción (docs/07 §7.5).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.tertiary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error con mensaje humano y botón "Reintentar".
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No pudimos cargar la información',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso flotante cuando el backend (Render gratuito) está despertando.
class ServerWakingBanner extends StatelessWidget {
  const ServerWakingBanner({super.key, required this.visible});

  final ValueNotifier<bool> visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, show, _) => AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: theme.colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Despertando el servidor… la primera carga puede '
                        'tardar hasta un minuto.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alias temporal de [mostrarToast] (docs/08 §8.7): el mensaje sale arriba
/// y no queda debajo de la barra flotante. Se borra en la fase 6.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
}) => mostrarToast(
  context,
  message,
  tipo: error ? TipoToast.error : TipoToast.exito,
);

/// Diálogo de confirmación con verbo explícito (docs/07 §7.7).
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String confirmarLabel,
  String cancelarLabel = 'No',
  bool destructivo = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelarLabel),
        ),
        TextButton(
          style: destructivo
              ? TextButton.styleFrom(foregroundColor: scheme.error)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmarLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
