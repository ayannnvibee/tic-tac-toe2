import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/game_colors.dart';
import 'mark_view.dart';

/// The game's emblem: an infinity loop holding an X and an O, on a white disc
/// with a lavender glow. Drawn as vectors so nothing is fetched or bundled.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.gameColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primaryFixed.withValues(alpha: 0.9),
            blurRadius: size * 0.22,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _InfinityPainter(start: colors.ctaStart, end: colors.xBadge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MarkView(mark: Mark.x, size: size * 0.16),
            SizedBox(width: size * 0.3),
            MarkView(mark: Mark.o, size: size * 0.16),
          ],
        ),
      ),
    );
  }
}

class _InfinityPainter extends CustomPainter {
  const _InfinityPainter({required this.start, required this.end});

  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.width * 0.37;
    final path = Path();
    // A lemniscate of Bernoulli, sampled.
    const steps = 96;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final denominator = 1 + math.sin(t) * math.sin(t);
      final point = Offset(
        center.dx + reach * math.cos(t) / denominator,
        center.dy + reach * 1.25 * math.sin(t) * math.cos(t) / denominator,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(colors: [start, end])
            .createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_InfinityPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}
