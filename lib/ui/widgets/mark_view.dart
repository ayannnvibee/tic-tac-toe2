import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/game_colors.dart';

/// Draws an X or an O as rounded vector strokes.
///
/// Proportions follow the design's 48-unit glyphs: the X spans 12 to 36, the
/// O has radius 13, and both use a stroke of 7 with round caps.
class MarkPainter extends CustomPainter {
  const MarkPainter({required this.mark, required this.color});

  final Mark mark;
  final Color color;

  static const double _designSize = 48;
  static const double _stroke = 7;
  static const double _xInset = 12;
  static const double _oRadius = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final scale = side / _designSize;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * scale
      ..strokeCap = StrokeCap.round;

    Offset at(double x, double y) => origin + Offset(x * scale, y * scale);

    switch (mark) {
      case Mark.x:
        const far = _designSize - _xInset;
        canvas
          ..drawLine(at(_xInset, _xInset), at(far, far), paint)
          ..drawLine(at(far, _xInset), at(_xInset, far), paint);
      case Mark.o:
        canvas.drawCircle(
          at(_designSize / 2, _designSize / 2),
          _oRadius * scale,
          paint,
        );
      case Mark.empty:
        break;
    }
  }

  @override
  bool shouldRepaint(MarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}

/// An X or an O in its player colour.
class MarkView extends StatelessWidget {
  const MarkView({
    super.key,
    required this.mark,
    required this.size,
    this.color,
  });

  final Mark mark;
  final double size;

  /// Defaults to the theme's colour for [mark].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: MarkPainter(
          mark: mark,
          color: color ?? (mark == Mark.x ? colors.xMark : colors.oMark),
        ),
      ),
    );
  }
}
