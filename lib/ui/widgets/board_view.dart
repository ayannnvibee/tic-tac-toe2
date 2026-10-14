import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import 'mark_view.dart';
import 'tactile.dart';

/// The square board.
///
/// Cells are always square and never smaller than [minCellSize]. The cell
/// size comes from the space available; when even the smallest cells do not
/// fit, the board is shown at that size inside a pan and pinch-zoom viewport
/// with zoom buttons underneath.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.onCellTap,
    this.winningLine,
    this.winLineProgress,
    this.focusCell,
  });

  final Board board;
  final List<Position>? winningLine;
  final ValueChanged<Position> onCellTap;

  /// How much of the stroke through [winningLine] is drawn, from 0 to 1.
  /// The whole stroke is drawn when this is null.
  final Animation<double>? winLineProgress;

  /// A cell to keep in view. When it changes on a board that is zoomed, the
  /// viewport pans gently until the cell is visible.
  final Position? focusCell;

  /// The smallest tap target, in logical pixels.
  static const double minCellSize = 44;

  /// A board with room to spare stops growing here, so cells on a tablet do
  /// not become enormous. A board that needs more to keep its cells at
  /// [minCellSize] may still use it.
  static const double preferredMaxSide = AppSpacing.maxContentWidth;

  /// Space between cells: the design uses 12 on 3x3 and 8 on 4x4.
  static double gapFor(int size) => size <= 3 ? 12 : (size <= 5 ? 8 : 6);

  static double _paddingFor(int size) => size <= 4 ? 12 : 8;

  /// The side of a [size] x [size] board whose cells are [cell] wide.
  static double sideFor(int size, double cell) =>
      size * cell + (size - 1) * gapFor(size) + 2 * _paddingFor(size);

  @override
  Widget build(BuildContext context) {
    final size = board.size;
    final smallest = sideFor(size, minCellSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.min(constraints.maxWidth, constraints.maxHeight);

        Widget tray(double cell) => _Tray(
          board: board,
          winningLine: winningLine,
          winLineProgress: winLineProgress,
          cell: cell,
          onCellTap: onCellTap,
        );

        if (smallest > available) {
          return _ZoomableBoard(
            boardSize: size,
            traySide: smallest,
            focusCell: focusCell,
            child: tray(minCellSize),
          );
        }

        final side = math.min(available, math.max(preferredMaxSide, smallest));
        final fixed = sideFor(size, 0);
        return Center(child: tray((side - fixed) / size));
      },
    );
  }
}

/// The tray of cells, with the winning stroke painted over it.
class _Tray extends StatelessWidget {
  const _Tray({
    required this.board,
    required this.winningLine,
    required this.winLineProgress,
    required this.cell,
    required this.onCellTap,
  });

  final Board board;
  final List<Position>? winningLine;
  final Animation<double>? winLineProgress;
  final double cell;
  final ValueChanged<Position> onCellTap;

  @override
  Widget build(BuildContext context) {
    final size = board.size;
    final gap = BoardView.gapFor(size);
    final padding = BoardView._paddingFor(size);
    final colors = context.gameColors;
    final line = winningLine;
    final winning = {...?line};

    final grid = Column(
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
    );

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colors.boardTray,
        borderRadius: BorderRadius.circular(
          math.min(AppRadii.lg, cell * 0.3 + padding),
        ),
        boxShadow: softShadow(context, strength: 1.5),
      ),
      child: line == null || line.length < 2
          ? grid
          : CustomPaint(
              key: const ValueKey('win-line'),
              foregroundPainter: _WinLinePainter(
                from: line.first,
                to: line.last,
                cell: cell,
                gap: gap,
                color: board.cellAt(line.first) == Mark.x
                    ? colors.xMark
                    : colors.oMark,
                progress: winLineProgress,
              ),
              child: grid,
            ),
    );
  }
}

/// A rounded stroke from the first winning cell to the last.
class _WinLinePainter extends CustomPainter {
  _WinLinePainter({
    required this.from,
    required this.to,
    required this.cell,
    required this.gap,
    required this.color,
    required this.progress,
  }) : super(repaint: progress);

  final Position from;
  final Position to;
  final double cell;
  final double gap;
  final Color color;
  final Animation<double>? progress;

  Offset _centre(Position position) => Offset(
    position.col * (cell + gap) + cell / 2,
    position.row * (cell + gap) + cell / 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = progress?.value ?? 1;
    if (drawn <= 0) return;

    final start = _centre(from);
    final end = Offset.lerp(start, _centre(to), drawn)!;
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = cell * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WinLinePainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.cell != cell ||
      oldDelegate.gap != gap ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
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

/// A board too big for the screen: it can be dragged and pinched, and the
/// buttons underneath zoom in, zoom out and fit the whole board for people
/// who cannot pinch.
class _ZoomableBoard extends StatefulWidget {
  const _ZoomableBoard({
    required this.boardSize,
    required this.traySide,
    required this.focusCell,
    required this.child,
  });

  final int boardSize;

  /// Side of the tray at its natural size, with [BoardView.minCellSize] cells.
  final double traySide;

  final Position? focusCell;
  final Widget child;

  @override
  State<_ZoomableBoard> createState() => _ZoomableBoardState();
}

class _ZoomableBoardState extends State<_ZoomableBoard>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 2.5;
  static const double _zoomStep = 1.3;
  static const Duration _panDuration = Duration(milliseconds: 260);

  /// A focused cell closer than this to the viewport edge is brought in.
  static const double _revealMargin = 8;

  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: _panDuration,
  )..addListener(_applyMotion);

  TransformationController? _transform;
  Matrix4Tween? _tween;
  Size _viewport = Size.zero;

  /// The scene the viewport looks at: the tray, centred in a canvas with the
  /// viewport's proportions, so that "fit" fills the viewport exactly.
  Size _canvas = Size.zero;

  double get _fitScale => _viewport.width / _canvas.width;

  @override
  void didUpdateWidget(_ZoomableBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focusCell;
    if (focus != null && focus != oldWidget.focusCell) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reveal(focus);
      });
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _transform?.dispose();
    super.dispose();
  }

  /// Sets up the viewport for a new size: natural scale, board centred.
  TransformationController _controllerFor(Size viewport) {
    final current = _transform;
    if (current != null && viewport == _viewport) return current;

    final tray = widget.traySide;
    _viewport = viewport;
    _canvas = Size(
      math.max(tray, tray * viewport.width / viewport.height),
      math.max(tray, tray * viewport.height / viewport.width),
    );
    _motion.stop();
    final next = TransformationController(
      _matrix(
        1,
        (viewport.width - _canvas.width) / 2,
        (viewport.height - _canvas.height) / 2,
      ),
    );
    if (current != null) {
      // The viewer still listens to the old controller until this build ends.
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    return _transform = next;
  }

  /// A transform with [scale] and translation, kept inside the canvas.
  Matrix4 _matrix(double scale, double dx, double dy) {
    final s = scale.clamp(_fitScale, _maxScale);
    final minDx = math.min(0.0, _viewport.width - _canvas.width * s);
    final minDy = math.min(0.0, _viewport.height - _canvas.height * s);
    return Matrix4.identity()
      ..setEntry(0, 0, s)
      ..setEntry(1, 1, s)
      ..setEntry(0, 3, dx.clamp(minDx, 0.0))
      ..setEntry(1, 3, dy.clamp(minDy, 0.0));
  }

  double get _scale => _transform!.value.entry(0, 0);
  Offset get _offset =>
      Offset(_transform!.value.entry(0, 3), _transform!.value.entry(1, 3));

  void _applyMotion() {
    final tween = _tween;
    if (tween == null) return;
    _transform?.value = tween.transform(
      Curves.easeInOutCubic.transform(_motion.value),
    );
  }

  void _moveTo(Matrix4 target) {
    final transform = _transform;
    if (transform == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      transform.value = target;
      return;
    }
    _tween = Matrix4Tween(begin: transform.value, end: target);
    _motion.forward(from: 0);
  }

  void _zoomBy(double factor) {
    if (_transform == null) return;
    final from = _scale;
    final to = (from * factor).clamp(_fitScale, _maxScale);
    // Keep whatever is at the centre of the viewport where it is.
    final centre = _viewport.center(Offset.zero);
    final scenePoint = (centre - _offset) / from;
    final offset = centre - scenePoint * to;
    _moveTo(_matrix(to, offset.dx, offset.dy));
  }

  void _fit() => _moveTo(_matrix(_fitScale, 0, 0));

  /// Pans, without changing the zoom, until [cell] is inside the viewport.
  void _reveal(Position cell) {
    if (_transform == null) return;
    final size = widget.boardSize;
    final step = BoardView.minCellSize + BoardView.gapFor(size);
    final trayOrigin = Offset(
      (_canvas.width - widget.traySide) / 2,
      (_canvas.height - widget.traySide) / 2,
    );
    final padding = BoardView._paddingFor(size);
    final inScene =
        (trayOrigin +
            Offset(padding + cell.col * step, padding + cell.row * step)) &
        const Size.square(BoardView.minCellSize);

    final scale = _scale;
    final onScreen = Rect.fromLTWH(
      inScene.left * scale + _offset.dx,
      inScene.top * scale + _offset.dy,
      inScene.width * scale,
      inScene.height * scale,
    );
    final safe = (Offset.zero & _viewport).deflate(_revealMargin);
    if (safe.contains(onScreen.topLeft) &&
        safe.contains(onScreen.bottomRight)) {
      return;
    }

    final offset = _viewport.center(Offset.zero) - inScene.center * scale;
    _moveTo(_matrix(scale, offset.dx, offset.dy));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: ColoredBox(
              color: scheme.surfaceContainerLow,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final transform = _controllerFor(constraints.biggest);
                  return InteractiveViewer(
                    key: const ValueKey('board-viewer'),
                    transformationController: transform,
                    constrained: false,
                    minScale: _fitScale,
                    maxScale: _maxScale,
                    onInteractionStart: (_) => _motion.stop(),
                    child: SizedBox.fromSize(
                      size: _canvas,
                      child: Center(child: widget.child),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ZoomControls(
          onZoomOut: () => _zoomBy(1 / _zoomStep),
          onFit: _fit,
          onZoomIn: () => _zoomBy(_zoomStep),
        ),
      ],
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomOut,
    required this.onFit,
    required this.onZoomIn,
  });

  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('zoom-controls'),
      decoration: BoxDecoration(
        color: context.gameColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: softShadow(context, strength: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundIconButton(
              key: const ValueKey('zoom-out'),
              icon: Icons.remove,
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
            ),
            const SizedBox(width: AppSpacing.sm),
            RoundIconButton(
              key: const ValueKey('zoom-fit'),
              icon: Icons.fit_screen,
              tooltip: 'Fit the whole board',
              onPressed: onFit,
            ),
            const SizedBox(width: AppSpacing.sm),
            RoundIconButton(
              key: const ValueKey('zoom-in'),
              icon: Icons.add,
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
            ),
          ],
        ),
      ),
    );
  }
}
