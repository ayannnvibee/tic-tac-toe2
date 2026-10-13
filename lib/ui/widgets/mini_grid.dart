import 'package:flutter/material.dart';

/// A tiny n x n grid of coloured squares, used in the "board grows" diagrams.
class MiniGrid extends StatelessWidget {
  const MiniGrid({
    super.key,
    required this.size,
    required this.dimension,
    required this.background,
    required this.cellColor,
    required this.accentColor,
    this.accentAntiDiagonal = false,
  });

  /// Cells per side.
  final int size;

  /// Width and height of the whole grid, in logical pixels.
  final double dimension;

  final Color background;
  final Color cellColor;

  /// Colour of the cells on the highlighted diagonal.
  final Color accentColor;

  /// Highlights the top-right to bottom-left diagonal instead.
  final bool accentAntiDiagonal;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: _MiniGridPainter(
          size: size,
          background: background,
          cellColor: cellColor,
          accentColor: accentColor,
          accentAntiDiagonal: accentAntiDiagonal,
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  const _MiniGridPainter({
    required this.size,
    required this.background,
    required this.cellColor,
    required this.accentColor,
    required this.accentAntiDiagonal,
  });

  final int size;
  final Color background;
  final Color cellColor;
  final Color accentColor;
  final bool accentAntiDiagonal;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final side = canvasSize.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size.square(side),
        Radius.circular(side * 0.2),
      ),
      Paint()..color = background,
    );

    final padding = side * 0.12;
    const gap = 2.0;
    final cell = (side - 2 * padding - gap * (size - 1)) / size;
    final radius = Radius.circular(cell * 0.2);
    final paint = Paint();

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final onLine = accentAntiDiagonal ? row + col == size - 1 : row == col;
        paint.color = onLine ? accentColor : cellColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              padding + col * (cell + gap),
              padding + row * (cell + gap),
              cell,
              cell,
            ),
            radius,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.background != background ||
      oldDelegate.cellColor != cellColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.accentAntiDiagonal != accentAntiDiagonal;
}
