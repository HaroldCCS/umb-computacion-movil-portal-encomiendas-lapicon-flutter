import 'package:flutter/material.dart';

import 'feedback_views.dart';

/// Pantalla temporal para una pestaña aún no construida.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.titulo,
    required this.icon,
    required this.mensaje,
  });

  final String titulo;
  final IconData icon;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: EmptyState(icon: icon, title: 'Muy pronto', message: mensaje),
    );
  }
}
