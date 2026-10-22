import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/feedback_views.dart';
import '../../data/models/resumen_calificaciones.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/resenas_screen.dart';

/// Perfil: datos, calificaciones recibidas, cambiar de rol y cerrar sesión.
/// La carga del perfil (`GET /api/users/:uid`) es la primera llamada
/// protegida de la Práctica 1.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final perfil = session.perfil;
        final rol = session.rol;
        final theme = Theme.of(context);
        if (perfil == null || rol == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(title: const Text('Mi perfil')),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(resumenCalificacionesProvider(perfil.uid));
              try {
                await session.recargar(silencioso: true);
              } on AppException catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, e.message, error: true);
                }
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Cabecera(
                  iniciales: perfil.iniciales,
                  nombre: perfil.nombreCompleto,
                  email: session.email ?? '',
                  rol: rol,
                ),
                const SizedBox(height: AppSpacing.lg),
                _CalificacionesCard(uid: perfil.uid),
                const SizedBox(height: AppSpacing.md),
                _Seccion(
                  titulo: 'DATOS DE CONTACTO',
                  children: [
                    _Dato(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: perfil.telefono,
                    ),
                    _Dato(
                      icon: Icons.public,
                      label: 'Nacionalidad',
                      value: perfil.nacionalidad,
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Editar perfil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/perfil/editar'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Seccion(
                  titulo: 'CUENTA',
                  children: [
                    ListTile(
                      leading: Icon(rol.opuesto.icon),
                      title: Text(
                        'Cambiar a ${rol.opuesto.nombre.toLowerCase()}',
                      ),
                      subtitle: Text(rol.opuesto.descripcion),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _cambiarRol(context, ref, rol.opuesto),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onTap: () => _cerrarSesion(context, ref),
                    ),
                  ],
                ),
                if (!session.rolEnServidor) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tu rol está guardado en este teléfono.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cambiarRol(
    BuildContext context,
    WidgetRef ref,
    Rol nuevo,
  ) async {
    try {
      await ref.read(sessionProvider).elegirRol(nuevo);
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Ahora estás en modo ${nuevo.nombre.toLowerCase()}.',
        );
      }
    } on AppException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, error: true);
    }
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Tendrás que volver a ingresar tu correo y contraseña.',
      confirmarLabel: 'Sí, cerrar sesión',
      destructivo: true,
    );
    if (ok) await ref.read(sessionProvider).cerrarSesion();
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.iniciales,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final String iniciales;
  final String nombre;
  final String email;
  final Rol rol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = rol.accent(theme.brightness);
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            iniciales,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          nombre,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty)
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Chip(
          avatar: Icon(
            rol.icon,
            size: 18,
            color: rol.onAccent(theme.brightness),
          ),
          label: Text(rol.nombre),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: rol.onAccent(theme.brightness),
          ),
          backgroundColor: accent,
          side: BorderSide.none,
          shape: const StadiumBorder(),
        ),
      ],
    );
  }
}

class _CalificacionesCard extends ConsumerWidget {
  const _CalificacionesCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumen = ref.watch(resumenCalificacionesProvider(uid));

    Widget body(ResumenCalificaciones r) {
      if (r.vacio) {
        return Text(
          'Aún no tienes calificaciones. Aparecerán aquí después de tu '
          'primera entrega.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
      final promedio = (r.promedio ?? 0)
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      return Row(
        children: [
          Text(promedio, style: theme.textTheme.displaySmall),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRow(value: r.promedio ?? 0),
                Text(
                  '${r.total} ${r.total == 1 ? 'calificación' : 'calificaciones'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _Seccion(
      titulo: 'CALIFICACIONES',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: resumen.when(
            data: body,
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              e is AppException
                  ? e.message
                  : 'No pudimos cargar tus calificaciones.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        if (resumen.hasValue && !resumen.requireValue.vacio)
          ListTile(
            leading: const Icon(Icons.reviews_outlined),
            title: const Text('Ver reseñas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.push(ResenasScreen.path, extra: ResenasArgs(uid: uid)),
          ),
      ],
    );
  }
}

/// Estrellas de solo lectura (con lectura accesible del valor).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 20});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Semantics(
      label: '${value.toStringAsFixed(1)} de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              value >= i
                  ? Icons.star_rounded
                  : (value >= i - 0.5
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
              color: color,
              size: size,
            ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                titulo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(value.isEmpty ? '—' : value),
      subtitle: Text(label),
    );
  }
}
