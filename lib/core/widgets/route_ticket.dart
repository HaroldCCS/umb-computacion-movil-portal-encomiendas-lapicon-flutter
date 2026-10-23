import 'package:flutter/material.dart';

import '../theme/tema.dart';
import 'presionable.dart';

/// Firma visual de Lapticon: la ruta como un pase de abordar (docs/07 §7.5,
/// re-estilo v2 de docs/08 §8.3).
///
/// Arriba: ORIGEN → DESTINO en grande. Si hay [details] o [trailing], se
/// dibuja una línea perforada con muescas laterales y la sección inferior.
class RouteTicket extends StatelessWidget {
  const RouteTicket({
    super.key,
    required this.origen,
    required this.destino,
    this.details = const [],
    this.trailing,
    this.onTap,
    this.accent,
    this.compact = false,
  });

  final String origen;
  final String destino;

  /// Pares etiqueta/valor de la parte inferior (p. ej. FECHA · VUELO).
  final List<TicketDetail> details;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Color del avión y la línea (por defecto, `marca`).
  final Color? accent;
  final bool compact;

  bool get _hasBottom => details.isNotEmpty || trailing != null;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final topHeight = (compact ? 84.0 : 104.0) * textScale;
    final accentColor = accent ?? c.marca;

    final top = SizedBox(
      height: topHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _City(label: 'ORIGEN', city: origen, compact: compact),
            ),
            Expanded(flex: 3, child: _FlightPath(color: accentColor)),
            Expanded(
              flex: 5,
              child: _City(
                label: 'DESTINO',
                city: destino,
                compact: compact,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // La etiqueta "Ruta de X a Y" ya lo dice; así el lector no lo repite.
        ExcludeSemantics(child: top),
        if (_hasBottom)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            // Wrap: con letra grande la insignia baja a otra línea en vez
            // de desbordar.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: [
                Wrap(spacing: 20, runSpacing: 10, children: details),
                ?trailing,
              ],
            ),
          ),
      ],
    );

    final pase = CustomPaint(
      painter: _TicketPainter(
        fill: c.superficie,
        // En claro la separación la da la sombra; en oscuro, el borde.
        border: c.conSombra ? null : c.separador,
        dash: c.separador,
        notchY: _hasBottom ? topHeight : null,
        shadows: c.sombraTarjeta,
      ),
      child: content,
    );

    return Semantics(
      label: 'Ruta de $origen a $destino',
      button: onTap != null,
      child: onTap == null
          ? pase
          : Presionable(onTap: onTap, escala: 0.98, child: pase),
    );
  }
}

/// Dato de la parte inferior del pase ("FECHA" / "12 dic").
class TicketDetail extends StatelessWidget {
  const TicketDetail({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: c.texto2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: c.texto,
            fontFeatures: cifras,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _City extends StatelessWidget {
  const _City({
    required this.label,
    required this.city,
    required this.compact,
    this.alignEnd = false,
  });

  final String label;
  final String city;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final alignment = alignEnd ? Alignment.centerRight : Alignment.centerLeft;
    // Space Grotesk (estilo display) también en el pase compacto.
    final estilo = context.t.displaySmall?.copyWith(
      fontSize: compact ? 24 : 32,
      height: 1.1,
      color: c.texto,
    );
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: c.texto2,
          ),
        ),
        const SizedBox(height: 2),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text(city, maxLines: 1, style: estilo),
          ),
        ),
      ],
    );
  }
}

class _FlightPath extends StatelessWidget {
  const _FlightPath({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(child: _Dashes(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.rotate(
              angle: 1.5708, // 90°: el avión apunta hacia el destino
              child: Icon(Icons.flight, color: color, size: 22),
            ),
          ),
          Expanded(child: _Dashes(color: color)),
        ],
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 7).floor().clamp(1, 40);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: 3, height: 1.5, color: color),
          ),
        );
      },
    );
  }
}

class _TicketPainter extends CustomPainter {
  _TicketPainter({
    required this.fill,
    required this.border,
    required this.dash,
    required this.notchY,
    required this.shadows,
  });

  final Color fill;
  final Color? border;
  final Color dash;
  final double? notchY;
  final List<BoxShadow> shadows;

  static const _notchRadius = 10.0;

  Path _shape(Size size) {
    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Medidas.radioTarjeta),
        ),
      );
    final y = notchY;
    if (y == null) return base;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: _notchRadius))
      ..addOval(
        Rect.fromCircle(center: Offset(size.width, y), radius: _notchRadius),
      );
    return Path.combine(PathOperation.difference, base, notches);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shape(size);
    // Las mismas sombras que una Tarjeta, siguiendo la forma con muescas.
    for (final s in shadows) {
      canvas.drawPath(
        path.shift(s.offset),
        Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (border != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = border!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final y = notchY;
    if (y != null) {
      final paint = Paint()
        ..color = dash
        ..strokeWidth = 1.5;
      var x = _notchRadius + 8;
      while (x < size.width - _notchRadius - 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 6, y), paint);
        x += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_TicketPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.dash != dash ||
      old.notchY != notchY ||
      old.shadows != shadows;
}
