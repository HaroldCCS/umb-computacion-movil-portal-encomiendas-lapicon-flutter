import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/esqueleto.dart';
import '../../core/widgets/grupo.dart';
import '../../core/widgets/hoja.dart';
import '../../core/widgets/pantalla.dart';
import '../../core/widgets/toast.dart';
import '../../data/models/rol.dart';
import '../../providers.dart';
import '../calificaciones/resenas_screen.dart';
import '../calificaciones/star_rating.dart';

/// Perfil estilo ajustes: cabecera, calificaciones recibidas, datos de
/// contacto y cuenta (cambiar de rol, cerrar sesión). La carga del perfil
/// (`GET /api/users/:uid`) es la primera llamada protegida de la Práctica 1.
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
        if (perfil == null || rol == null) return const SizedBox.shrink();
        final c = context.c;

        return Pantalla(
          titulo: 'Mi perfil',
          conBarraPestanas: true,
          alActualizar: () async {
            ref.invalidate(resumenCalificacionesProvider(perfil.uid));
            try {
              await session.recargar(silencioso: true);
            } on AppException catch (e) {
              if (context.mounted) {
                mostrarToast(context, e.message, tipo: TipoToast.error);
              }
            }
          },
          hijos: [
            _Cabecera(
              nombre: perfil.nombreCompleto,
              email: session.email ?? '',
              rol: rol,
            ),
            _Calificaciones(uid: perfil.uid),
            Grupo(
              titulo: 'Datos de contacto',
              hijos: [
                Fila(
                  'Teléfono',
                  Text(perfil.telefono.isEmpty ? '—' : perfil.telefono),
                ),
                Fila(
                  'Nacionalidad',
                  Text(perfil.nacionalidad.isEmpty ? '—' : perfil.nacionalidad),
                ),
                FilaAccion(
                  titulo: 'Editar perfil',
                  icono: Icons.edit_outlined,
                  onTap: () => context.push(Routes.editarPerfil),
                ),
              ],
            ),
            Grupo(
              titulo: 'Cuenta',
              pie: session.rolEnServidor
                  ? null
                  : 'Tu rol está guardado en este teléfono.',
              hijos: [
                FilaAccion(
                  titulo: 'Cambiar a ${rol.opuesto.nombre.toLowerCase()}',
                  subtitulo: rol.opuesto.descripcion,
                  icono: rol.opuesto.icono,
                  // Ámbar oscuro (legible) para remitente, cielo para viajero.
                  colorIcono: rol.opuesto == Rol.remitente
                      ? c.atencion
                      : c.viajero,
                  onTap: () => _cambiarRol(context, ref, rol.opuesto),
                ),
                FilaAccion(
                  titulo: 'Cerrar sesión',
                  icono: Icons.logout,
                  destructiva: true,
                  onTap: () => _cerrarSesion(context, ref),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Reversible: un toque (docs/08 §8.6-5).
  Future<void> _cambiarRol(
    BuildContext context,
    WidgetRef ref,
    Rol nuevo,
  ) async {
    try {
      await ref.read(sessionProvider).elegirRol(nuevo);
      if (context.mounted) {
        mostrarToast(
          context,
          'Ahora estás en modo ${nuevo.nombre.toLowerCase()}.',
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        mostrarToast(context, e.message, tipo: TipoToast.error);
      }
    }
  }

  /// Con consecuencias: hoja que explica qué pasa.
  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final ok = await confirmarConHoja(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Tendrás que volver a ingresar tu correo y contraseña.',
      confirmarTexto: 'Sí, cerrar sesión',
      cancelarTexto: 'No, seguir aquí',
      destructivo: true,
    );
    if (ok) await ref.read(sessionProvider).cerrarSesion();
  }
}

/// Avatar grande, nombre, correo y el rol actual con su acento.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final String nombre;
  final String email;
  final Rol rol;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        Avatar(nombre, tam: 80),
        const SizedBox(height: 12),
        Text(nombre, style: context.t.titleLarge, textAlign: TextAlign.center),
        if (email.isNotEmpty)
          Text(email, style: TextStyle(fontSize: 15, color: c.texto2)),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label: 'Rol actual: ${rol.nombre}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.acento(rol),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(rol.icono, size: 18, color: c.sobreAcento(rol)),
                const SizedBox(width: 6),
                Text(
                  rol.nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.sobreAcento(rol),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Calificaciones extends ConsumerWidget {
  const _Calificaciones({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final resumen = ref.watch(resumenCalificacionesProvider(uid));

    final Widget cuerpo = switch (resumen) {
      AsyncData(value: final r) when r.vacio => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Aún no tienes calificaciones. Aparecerán aquí después de tu '
          'primera entrega.',
          style: TextStyle(fontSize: 15, color: c.texto2),
        ),
      ),
      AsyncData(value: final r) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              (r.promedio ?? 0).toStringAsFixed(1).replaceAll('.', ','),
              style: context.t.displaySmall?.copyWith(color: c.texto),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(value: r.promedio ?? 0, size: 20),
                  Text(
                    '${r.total} '
                    '${r.total == 1 ? 'calificación' : 'calificaciones'}',
                    style: TextStyle(fontSize: 15, color: c.texto2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error is AppException
              ? error.message
              : 'No pudimos cargar tus calificaciones.',
          style: TextStyle(fontSize: 15, color: c.texto2),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(16),
        child: Esqueleto(alto: 44),
      ),
    };

    return Grupo(
      titulo: 'Calificaciones',
      hijos: [
        cuerpo,
        if (resumen.hasValue && !resumen.requireValue.vacio)
          FilaAccion(
            titulo: 'Ver reseñas',
            icono: Icons.reviews_outlined,
            colorIcono: Pastel.ambar,
            onTap: () =>
                context.push(ResenasScreen.path, extra: ResenasArgs(uid: uid)),
          ),
      ],
    );
  }
}
