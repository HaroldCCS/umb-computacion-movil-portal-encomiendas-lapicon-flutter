import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../utils/formatters.dart';

/// Toda cifra de dinero pasa por aquí: `USD 25`, `COP 50.000`, con cifras
/// tabulares para que las columnas no "bailen" (docs/08 §8.6-3).
class Monto extends StatelessWidget {
  const Monto(this.valor, {super.key, required this.moneda, this.estilo});

  final num valor;
  final String moneda;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Text(
      Fmt.dinero(valor, moneda),
      style: (estilo ?? const TextStyle()).copyWith(fontFeatures: cifras),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
