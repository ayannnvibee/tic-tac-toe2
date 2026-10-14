import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/board_view.dart';

import 'app_harness.dart';

/// The zoom the board viewer is currently showing.
double _scale(WidgetTester tester) => tester
    .widget<InteractiveViewer>(boardViewer)
    .transformationController!
    .value
    .entry(0, 0);

bool _fullyInside(Rect outer, Rect inner) =>
    inner.left >= outer.left - 0.01 &&
    inner.top >= outer.top - 0.01 &&
    inner.right <= outer.right + 0.01 &&
    inner.bottom <= outer.bottom + 0.01;

void main() {
  group('layout', () {
    // Whether a board of that size needs zooming on that surface.
    final expectations = <(String, Size, int), bool>{
      ('360×640', smallPhone, 3): false,
      ('360×640', smallPhone, 6): false,
      ('360×640', smallPhone, 10): true,
      ('412×915', tallPhone, 3): false,
      ('412×915', tallPhone, 6): false,
      ('412×915', tallPhone, 10): true,
      ('7-inch tablet', sevenInchTablet, 3): false,
      ('7-inch tablet', sevenInchTablet, 6): false,
      ('7-inch tablet', sevenInchTablet, 10): false,
    };

    expectations.forEach((entry, zooms) {
      final (name, surface, boardSize) = entry;
      testWidgets('$boardSize×$boardSize on $name', (tester) async {
        await pumpApp(tester, size: surface, boardSize: boardSize);
        expect(tester.takeException(), isNull);
        await tester.openGame();
        expect(tester.takeException(), isNull);

        expect(textOf(tester, 'board-size'), '$boardSize × $boardSize');
        expect(allCells, findsNWidgets(boardSize * boardSize));

        // Cells are square and never smaller than a 44dp tap target.
        for (final element in allCells.evaluate()) {
          final box = element.size!;
          expect(box.width, closeTo(box.height, 0.01));
          expect(box.width, greaterThanOrEqualTo(BoardView.minCellSize));
        }

        // Zoom buttons appear only when the board does not fit.
        expect(zoomControls, zooms ? findsOneWidget : findsNothing);
        expect(boardViewer, zooms ? findsOneWidget : findsNothing);

        final screen = Offset.zero & surface;
        if (!zooms) {
          // The whole board is on screen, and centred left to right.
          final first = tester.getRect(cell(0, 0));
          final last = tester.getRect(cell(boardSize - 1, boardSize - 1));
          expect(_fullyInside(screen, first), isTrue);
          expect(_fullyInside(screen, last), isTrue);
          expect(first.left, closeTo(surface.width - last.right, 0.5));
        }

        // The header, the score and New Game are always fully on screen.
        for (final key in ['board-size', 'score-human', 'new-game']) {
          expect(
            _fullyInside(screen, tester.getRect(find.byKey(ValueKey(key)))),
            isTrue,
            reason: key,
          );
        }
      });
    });

    testWidgets('a 10×10 board on a tablet uses the width to keep 44dp cells', (
      tester,
    ) async {
      await pumpApp(tester, size: sevenInchTablet, boardSize: 10);
      await tester.openGame();

      final box = tester.getSize(cell(0, 0));
      expect(box.width, greaterThanOrEqualTo(BoardView.minCellSize));
      // Wider than the 480dp the rest of the layout is held to.
      final first = tester.getRect(cell(0, 0));
      final last = tester.getRect(cell(0, 9));
      expect(last.right - first.left, greaterThan(480));
    });
  });

  group('zoomed board', () {
    Future<FakeAi> open(WidgetTester tester) async {
      final ai = await pumpApp(tester, size: smallPhone, boardSize: 10);
      await tester.openGame();
      return ai;
    }

    testWidgets('starts at full size, centred on the middle of the board', (
      tester,
    ) async {
      await open(tester);

      expect(_scale(tester), 1);
      expect(tester.getSize(cell(0, 0)).width, BoardView.minCellSize);
      final viewer = tester.getRect(boardViewer);
      // The middle is in view and the corners are not.
      expect(_fullyInside(viewer, tester.getRect(cell(4, 4))), isTrue);
      expect(viewer.overlaps(tester.getRect(cell(0, 0))), isFalse);
      expect(viewer.overlaps(tester.getRect(cell(9, 9))), isFalse);
    });

    testWidgets('fit shows the whole board', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('zoom-fit')));
      await tester.pumpAndSettle();

      expect(_scale(tester), lessThan(1));
      final viewer = tester.getRect(boardViewer);
      expect(_fullyInside(viewer, tester.getRect(cell(0, 0))), isTrue);
      expect(_fullyInside(viewer, tester.getRect(cell(9, 9))), isTrue);
      expect(_fullyInside(viewer, tester.getRect(cell(0, 9))), isTrue);
      expect(_fullyInside(viewer, tester.getRect(cell(9, 0))), isTrue);
    });

    testWidgets('zoom in and zoom out change the scale within limits', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('zoom-in')));
      await tester.pumpAndSettle();
      final zoomedIn = _scale(tester);
      expect(zoomedIn, greaterThan(1));
      // The middle of the board stays in the middle of the viewport.
      final viewer = tester.getRect(boardViewer);
      expect(viewer.overlaps(tester.getRect(cell(4, 4))), isTrue);

      await tester.tap(find.byKey(const ValueKey('zoom-out')));
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(1, 0.001));

      // Zooming out stops at "fit" and zooming in stops at the maximum.
      for (var i = 0; i < 12; i++) {
        await tester.tap(find.byKey(const ValueKey('zoom-out')));
        await tester.pumpAndSettle();
      }
      final smallest = _scale(tester);
      await tester.tap(find.byKey(const ValueKey('zoom-fit')));
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(smallest, 0.001));

      for (var i = 0; i < 12; i++) {
        await tester.tap(find.byKey(const ValueKey('zoom-in')));
        await tester.pumpAndSettle();
      }
      expect(_scale(tester), closeTo(2.5, 0.001));
    });

    testWidgets('can be dragged to reach a corner', (tester) async {
      await open(tester);
      await tester.drag(boardViewer, const Offset(300, 300));
      await tester.pumpAndSettle();

      final viewer = tester.getRect(boardViewer);
      expect(_fullyInside(viewer, tester.getRect(cell(0, 0))), isTrue);
    });

    testWidgets('cells can still be tapped', (tester) async {
      final ai = await open(tester);
      ai.script.add(const Position(4, 5));
      await tester.tapCells(const [Position(4, 4)]);

      expect(xAt(4, 4), findsOneWidget);
      expect(oAt(4, 5), findsOneWidget);
    });

    testWidgets('pans to the computer move when it lands out of view', (
      tester,
    ) async {
      final ai = await open(tester);
      final viewer = tester.getRect(boardViewer);
      expect(viewer.overlaps(tester.getRect(cell(9, 9))), isFalse);

      ai.script.add(const Position(9, 9));
      await tester.tap(cell(4, 4));
      await tester.pump();
      await tester.pump();
      // The pan is gradual: part way through, the move is not yet in view.
      await tester.pump(const Duration(milliseconds: 40));
      expect(_fullyInside(viewer, tester.getRect(cell(9, 9))), isFalse);

      await tester.pumpAndSettle();
      expect(oAt(9, 9), findsOneWidget);
      expect(_fullyInside(viewer, tester.getRect(cell(9, 9))), isTrue);
      // Panning did not change the zoom.
      expect(_scale(tester), 1);
    });

    testWidgets('does not move when the computer plays in view', (
      tester,
    ) async {
      final ai = await open(tester);
      final before = tester.getRect(cell(4, 4));

      ai.script.add(const Position(4, 5));
      await tester.tapCells(const [Position(4, 4)]);
      expect(tester.getRect(cell(4, 4)), before);
    });

    testWidgets('pans straight there with reduce motion on', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final ai = await open(tester);
      final viewer = tester.getRect(boardViewer);

      ai.script.add(const Position(0, 0));
      await tester.tap(cell(4, 4));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(_fullyInside(viewer, tester.getRect(cell(0, 0))), isTrue);
    });
  });
}
