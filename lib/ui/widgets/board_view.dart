import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import 'mark_view.dart';
import 'tactile.dart';

/// The square board. It fills the space it is given, up to a comfortable
/// maximum, and never lets a cell shrink below [minCellSize]; a board that
/// cannot fit at that size scrolls in both directions instead.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.onCellTap,
    this.winningLine,
  });

  final Board board;
  final List<Position>? winningLine;
  final ValueChanged<Position> onCellTap;

  /// The smallest tap target, in logical pixels.
  static const double minCellSize = 44;

  /// The play field never grows past this, so tablets keep phone proportions.
  static const double maxBoardSide = AppSpacing.maxContentWidth;

  /// Space between cells: the design uses 12 on 3x3 and 8 on 4x4.
  static double gapFor(int size) => size <= 3 ? 12 : (size <= 5 ? 8 : 6);

  static double _paddingFor(int size) => size <= 4 ? 12 : 8;

  @override
  Widget build(BuildContext context) {
    final size = board.size;
    final gap = gapFor(size);
    final padding = _paddingFor(size);
    final fixed = 2 * padding + (size - 1) * gap;
    final winning = {...?winningLine};

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          maxBoardSide,
        );
        final fitted = (available - fixed) / size;
        final scrolls = fitted < minCellSize;
        final cell = scrolls ? minCellSize : fitted;

        final tray = _Tray(
          board: board,
          winning: winning,
          cell: cell,
          gap: gap,
          padding: padding,
          onCellTap: onCellTap,
        );
        if (!scrolls) return Center(child: tray);

        return Center(
          child: SingleChildScrollView(
            key: const ValueKey('board-scroll-vertical'),
            child: SingleChildScrollView(
              key: const ValueKey('board-scroll-horizontal'),
              scrollDirection: Axis.horizontal,
              child: tray,
            ),
          ),
        );
      },
    );
  }
}

class _Tray extends StatelessWidget {
  const _Tray({
    required this.board,
    required this.winning,
    required this.cell,
    required this.gap,
    required this.padding,
    required this.onCellTap,
  });

  final Board board;
  final Set<Position> winning;
  final double cell;
  final double gap;
  final double padding;
  final ValueChanged<Position> onCellTap;

  @override
  Widget build(BuildContext context) {
    final size = board.size;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.gameColors.boardTray,
        borderRadius: BorderRadius.circular(
          math.min(AppRadii.lg, cell * 0.3 + padding),
        ),
        boxShadow: softShadow(context, strength: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < size; row++) ...[
            if (row > 0) SizedBox(height: gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var col = 0; col < size; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  _Cell(
                    position: Position(row, col),
                    mark: board.cellAt(Position(row, col)),
                    winning: winning.contains(Position(row, col)),
                    size: cell,
                    onTap: onCellTap,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.position,
    required this.mark,
    required this.winning,
    required this.size,
    required this.onTap,
  });

  final Position position;
  final Mark mark;
  final bool winning;
  final double size;
  final ValueChanged<Position> onTap;

  String get _contents => switch (mark) {
    Mark.x => 'X',
    Mark.o => 'O',
    Mark.empty => 'empty',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    // 16 on a phone-sized 3x3 cell, tighter as the cells shrink.
    final radius = BorderRadius.circular(math.min(AppRadii.md, size * 0.28));
    final id = '${position.row}-${position.col}';

    return Semantics(
      button: true,
      label:
          'Row ${position.row + 1}, column ${position.col + 1}, '
          '$_contents${winning ? ', winning line' : ''}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: softShadow(context),
        ),
        child: Material(
          key: ValueKey('cell-$id'),
          color: winning ? colors.winFill : colors.cell,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: winning
                ? BorderSide(color: colors.winOutline, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(position),
            child: Center(
              child: mark == Mark.empty
                  ? Container(
                      width: math.max(4, size * 0.11),
                      height: math.max(4, size * 0.11),
                      decoration: BoxDecoration(
                        color: colors.emptyDot,
                        shape: BoxShape.circle,
                      ),
                    )
                  : MarkView(
                      key: ValueKey('mark-${mark == Mark.x ? 'x' : 'o'}-$id'),
                      mark: mark,
                      size: size * 0.5,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
