import 'package:flutter/material.dart';

import '../../data/models/estado.dart';
import 'insignia.dart';

/// Alias temporal de [Insignia] para las pantallas que aún no migran
/// (docs/08 §8.7). Se borra en la fase 6.
class StatusChip extends StatelessWidget {
  const StatusChip._(this._insignia);

  factory StatusChip.encomienda(EstadoEncomienda estado) =>
      StatusChip._(Insignia.encomienda(estado));

  factory StatusChip.viaje(EstadoViaje estado) =>
      StatusChip._(Insignia.viaje(estado));

  final Insignia _insignia;

  @override
  Widget build(BuildContext context) => _insignia;
}
