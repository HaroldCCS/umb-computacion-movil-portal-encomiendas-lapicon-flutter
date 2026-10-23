import 'package:flutter/material.dart';

import '../../data/models/rol.dart';
import '../theme/tema.dart';
import '../utils/formatters.dart';
import 'avatar.dart';
import 'presionable.dart';

/// Encabezado de Inicio: logotipo (con el acento del rol), saludo, fecha,
/// acciones y avatar que lleva al perfil. Sin el ojo de la guía (docs/08
/// §8.8-5).
class EncabezadoApp extends StatelessWidget {
  const EncabezadoApp({
    super.key,
    required this.usuario,
    required this.rol,
    this.fecha,
    this.acciones = const [],
    this.alTocarAvatar,
  });

  /// Nombre completo; se saluda con el primero.
  final String usuario;
  final Rol rol;

  /// Para pruebas; por defecto, hoy.
  final DateTime? fecha;
  final List<Widget> acciones;
  final VoidCallback? alTocarAvatar;

  static String saludo(String usuario) {
    final nombre = usuario.trim().split(RegExp(r'\s+')).first;
    return nombre.isEmpty ? 'Hola' : 'Hola, $nombre';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Medidas.margen,
        MediaQuery.paddingOf(context).top + 10,
        Medidas.margen,
        8,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: Degradados.de(rol),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                rol == Rol.remitente
                    ? Icons.inventory_2_rounded
                    : Icons.flight_takeoff_rounded,
                color: rol == Rol.remitente ? c.remitente : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    saludo(usuario),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: c.texto,
                    ),
                  ),
                ),
                Text(
                  Fmt.fechaLarga(fecha ?? DateTime.now()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.texto2,
                  ),
                ),
              ],
            ),
          ),
          for (final a in acciones) ...[a, const SizedBox(width: 8)],
          Semantics(
            button: true,
            label: 'Tu perfil',
            onTap: alTocarAvatar,
            excludeSemantics: true,
            child: Presionable(
              onTap: alTocarAvatar,
              escala: 0.9,
              child: SizedBox.square(
                dimension: 48,
                child: Center(child: Avatar(usuario)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
