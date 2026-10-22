import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Firma visual de Lapticon: la ruta como un pase de abordar (docs/07 §7.5).
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

  /// Color del avión y la línea (por defecto, el acento terciario).
  final Color? accent;
  final bool compact;

  bool get _hasBottom => details.isNotEmpty || trailing != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final topHeight = (compact ? 84.0 : 104.0) * textScale;
    final accentColor = accent ?? scheme.tertiary;

    final top = SizedBox(
      height: topHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                for (final d in details) ...[
                  Flexible(child: d),
                  const SizedBox(width: AppSpacing.lg),
                ],
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
      ],
    );

    return Semantics(
      label: 'Ruta de $origen a $destino',
      button: onTap != null,
      child: CustomPaint(
        painter: _TicketPainter(
          fill: scheme.surfaceContainerLowest,
          border: scheme.outlineVariant,
          dash: scheme.outlineVariant,
          notchY: _hasBottom ? topHeight : null,
          shadow: theme.brightness == Brightness.light,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: content,
          ),
        ),
      ),
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
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: t.labelSmall?.copyWith(color: muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: t.titleMedium,
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
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final alignment = alignEnd ? Alignment.centerRight : Alignment.centerLeft;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: t.labelSmall?.copyWith(color: muted)),
        const SizedBox(height: 2),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text(
              city,
              maxLines: 1,
              style: (compact ? t.headlineSmall : t.displaySmall)?.copyWith(
                height: 1.1,
              ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
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
    required this.shadow,
  });

  final Color fill;
  final Color border;
  final Color dash;
  final double? notchY;
  final bool shadow;

  static const _notchRadius = 10.0;

  Path _shape(Size size) {
    final base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.card),
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
    if (shadow) {
      canvas.drawShadow(path, const Color(0x33000000), 3, false);
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

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
      old.shadow != shadow;
}
