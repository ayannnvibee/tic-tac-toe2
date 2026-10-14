import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/ui/theme/app_theme.dart';
import 'package:tic_tac_toe_infinity/ui/theme/game_colors.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/board_view.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/mark_view.dart';

import 'app_harness.dart';

Future<List<Position>> _pumpBoard(
  WidgetTester tester,
  Board board, {
  Size area = const Size(358, 420),
  List<Position>? winningLine,
}) async {
  final taps = <Position>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: area,
            child: BoardView(
              board: board,
              winningLine: winningLine,
              onCellTap: taps.add,
            ),
          ),
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('cells are square and the board is centred', (tester) async {
    for (final size in [3, 4, 5, 6]) {
      await _pumpBoard(tester, Board.empty(size));
      expect(allCells, findsNWidgets(size * size));

      for (final element in allCells.evaluate()) {
        final box = element.size!;
        expect(box.width, closeTo(box.height, 0.01));
        expect(box.width, greaterThanOrEqualTo(BoardView.minCellSize));
      }
      final first = tester.getRect(cell(0, 0));
      final last = tester.getRect(cell(size - 1, size - 1));
      final area = tester.getRect(find.byType(BoardView));
      expect(
        first.left - area.left,
        closeTo(area.right - last.right, 0.01),
        reason: 'size $size is centred horizontally',
      );
      expect(
        first.top - area.top,
        closeTo(area.bottom - last.bottom, 0.01),
        reason: 'size $size is centred vertically',
      );
      expect(boardViewer, findsNothing);
      expect(zoomControls, findsNothing);
    }
  });

  testWidgets('a board too big to fit keeps 44dp cells and can be panned', (
    tester,
  ) async {
    await _pumpBoard(tester, Board.empty(10));

    expect(allCells, findsNWidgets(100));
    final box = tester.getSize(cell(0, 0));
    expect(box.width, BoardView.minCellSize);
    expect(box.height, BoardView.minCellSize);
    expect(boardViewer, findsOneWidget);
    expect(zoomControls, findsOneWidget);

    // The far corner is reachable by dragging.
    await tester.drag(boardViewer, const Offset(-600, -600));
    await tester.pumpAndSettle();
    final area = tester.getRect(boardViewer);
    expect(area.contains(tester.getCenter(cell(9, 9))), isTrue);
  });

  testWidgets('taps report the cell position', (tester) async {
    final taps = await _pumpBoard(tester, Board.empty(4));
    await tester.tap(cell(2, 3));
    await tester.tap(cell(0, 0));
    expect(taps, const [Position(2, 3), Position(0, 0)]);
  });

  testWidgets('marks are drawn as vectors in the player colours', (
    tester,
  ) async {
    final board = Board.empty(3)
        .place(const Position(0, 0), Mark.x)
        .place(const Position(1, 1), Mark.o);
    await _pumpBoard(tester, board);

    MarkPainter painterOf(Finder mark) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(of: mark, matching: find.byType(CustomPaint)),
                )
                .painter!
            as MarkPainter;

    final x = painterOf(xAt(0, 0));
    final o = painterOf(oAt(1, 1));
    expect(x.mark, Mark.x);
    expect(x.color, GameColors.light.xMark);
    expect(o.mark, Mark.o);
    expect(o.color, GameColors.light.oMark);
    // No glyph text is used for the marks.
    expect(find.text('X'), findsNothing);
    expect(find.text('O'), findsNothing);
  });

  testWidgets('winning cells are highlighted', (tester) async {
    var board = Board.empty(3);
    const line = [Position(0, 0), Position(1, 1), Position(2, 2)];
    for (final position in line) {
      board = board.place(position, Mark.x);
    }
    await _pumpBoard(tester, board, winningLine: line);

    Color colorOf(int row, int col) =>
        tester.widget<Material>(cell(row, col)).color!;
    for (final position in line) {
      expect(colorOf(position.row, position.col), GameColors.light.winFill);
    }
    expect(colorOf(0, 1), GameColors.light.cell);
    expect(colorOf(2, 0), GameColors.light.cell);
  });

  group('contrast', () {
    double luminance(Color color) => color.computeLuminance();
    double contrast(Color a, Color b) {
      final high = math.max(luminance(a), luminance(b));
      final low = math.min(luminance(a), luminance(b));
      return (high + 0.05) / (low + 0.05);
    }

    for (final (name, colors) in [
      ('light', GameColors.light),
      ('dark', GameColors.dark),
    ]) {
      test('X and O meet WCAG AA on a cell in the $name theme', () {
        expect(contrast(colors.xMark, colors.cell), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.oMark, colors.cell), greaterThanOrEqualTo(4.5));
      });

      test('X and O stay visible on a winning cell in the $name theme', () {
        // WCAG AA for graphics (1.4.11) asks for 3:1.
        expect(contrast(colors.xMark, colors.winFill), greaterThanOrEqualTo(3));
        expect(contrast(colors.oMark, colors.winFill), greaterThanOrEqualTo(3));
      });

      test('X and O are clearly different colours in the $name theme', () {
        final x = HSLColor.fromColor(colors.xMark).hue;
        final o = HSLColor.fromColor(colors.oMark).hue;
        final apart = (x - o).abs();
        expect(math.min(apart, 360 - apart), greaterThan(90));
      });

      test('button labels meet WCAG AA in the $name theme', () {
        for (final fill in [
          colors.ctaStart,
          colors.ctaEnd,
          colors.retryStart,
          colors.retryEnd,
        ]) {
          expect(contrast(colors.onCta, fill), greaterThanOrEqualTo(4.5));
        }
      });
    }

    test('body text meets WCAG AA on the page and on cards', () {
      for (final (theme, colors) in [
        (AppTheme.light, GameColors.light),
        (AppTheme.dark, GameColors.dark),
      ]) {
        final scheme = theme.colorScheme;
        for (final background in [scheme.surface, colors.card, colors.inset]) {
          expect(
            contrast(scheme.onSurface, background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.onSurfaceVariant, background),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });
  });
}
