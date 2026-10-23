import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índices de las pestañas del inicio (iguales para ambos roles en Chats y
/// Perfil; ver `HomeShell`).
abstract final class Pestanas {
  static const inicio = 0; // Inicio (remitente) · Mi viaje (viajero)
  static const segunda = 1; // Envíos (remitente) · Explorar (viajero)
  static const chats = 2;
  static const perfil = 3;
}

/// Pestaña visible del inicio. Las pantallas la cambian con
/// `ref.read(pestanaInicioProvider.notifier).ir(Pestanas.perfil)`.
/// Se descarta con el `HomeShell`: al volver a iniciar sesión se abre en la
/// primera pestaña.
final pestanaInicioProvider = NotifierProvider.autoDispose<PestanaInicio, int>(
  PestanaInicio.new,
);

class PestanaInicio extends Notifier<int> {
  @override
  int build() => Pestanas.inicio;

  void ir(int indice) => state = indice;
}
