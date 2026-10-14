import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/ui/screens/game_screen.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/board_view.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/result_overlay.dart';

import 'app_harness.dart';

final Finder _overlay = find.byType(ResultOverlay);
final Finder _winLine = find.byKey(const ValueKey('win-line'));

/// Plays the human's winning round up to, but not including, the last tap.
Future<void> _setUpWinningTap(WidgetTester tester, FakeAi ai) async {
  ai.script.addAll(humanWinReplies);
  await tester.tapCells(humanWinTaps.sublist(0, 2));
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  group('result card', () {
    testWidgets('human win: title, subtitle, Next Level, then a bigger board', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);

      expect(textOf(tester, 'result-title'), 'YOU WIN!');
      expect(textOf(tester, 'result-subtitle'), 'Next level: 4 × 4');
      expect(find.text('NEXT LEVEL'), findsOneWidget);
      expect(find.text('RETRY LEVEL'), findsNothing);
      expect(find.text('RESTART'), findsNothing);

      await tester.continueFromResult();
      expect(_overlay, findsNothing);
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(allCells, findsNWidgets(16));
      expect(textOf(tester, 'score-human'), '1');
      expect(textOf(tester, 'score-computer'), '0');
    });

    testWidgets('computer win: title, subtitle, Retry Level, same size', (
      tester,
    ) async {
      final ai = await pumpApp(tester, boardSize: 4);
      await tester.openGame();
      await tester.playRound(
        ai,
        const [Position(0, 0), Position(0, 1), Position(1, 3), Position(2, 0)],
        const [Position(3, 0), Position(3, 1), Position(3, 2), Position(3, 3)],
      );

      expect(textOf(tester, 'result-title'), 'COMPUTER WINS!');
      expect(textOf(tester, 'result-subtitle'), 'Try 4 × 4 again');
      expect(find.text('RETRY LEVEL'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('RESTART'), findsNothing);

      await tester.continueFromResult();
      expect(_overlay, findsNothing);
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(allCells, findsNWidgets(16));
      expect(oAt(3, 0), findsNothing);
      expect(textOf(tester, 'score-human'), '1');
      expect(textOf(tester, 'score-computer'), '1');
    });

    testWidgets('draw: title, subtitle, Restart, then 3×3 with 0/0', (
      tester,
    ) async {
      final ai = await pumpApp(tester, boardSize: 4);
      await tester.openGame();
      expect(textOf(tester, 'score-human'), '1');
      await tester.playRound(ai, draw4x4Taps, draw4x4Replies);

      expect(textOf(tester, 'result-title'), "IT'S A DRAW!");
      expect(textOf(tester, 'result-subtitle'), 'Back to 3 × 3');
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('RETRY LEVEL'), findsNothing);
      // Nobody won, so there is no line to draw.
      expect(_winLine, findsNothing);

      await tester.continueFromResult();
      expect(_overlay, findsNothing);
      expect(textOf(tester, 'board-size'), '3 × 3');
      expect(allCells, findsNWidgets(9));
      expect(textOf(tester, 'score-human'), '0');
      expect(textOf(tester, 'score-computer'), '0');
    });
  });

  group('round end sequence', () {
    testWidgets('the line is drawn first, then the card appears', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await _setUpWinningTap(tester, ai);
      expect(_winLine, findsNothing);

      await tester.tap(cell(0, 2));
      await tester.pump();
      expect(xAt(0, 2), findsOneWidget);
      expect(_winLine, findsOneWidget);
      expect(_overlay, findsNothing);

      // Half way through the stroke the card is still hidden.
      await tester.pump(GameScreen.winLineDuration ~/ 2);
      expect(_overlay, findsNothing);

      await tester.pump(GameScreen.winLineDuration);
      await tester.pump();
      expect(_overlay, findsOneWidget);

      // The card itself eases in.
      final opacity = find.descendant(
        of: _overlay,
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(opacity.first).opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(opacity.first).opacity, 1);
    });

    testWidgets('the stroke takes between 400 and 600 ms', (tester) async {
      expect(
        GameScreen.winLineDuration.inMilliseconds,
        inInclusiveRange(400, 600),
      );
    });

    testWidgets('taps are ignored during the line animation', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await _setUpWinningTap(tester, ai);

      await tester.tap(cell(0, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_overlay, findsNothing);
      final requests = ai.requests.length;

      await tester.tap(cell(2, 2));
      await tester.pump();
      await tester.tap(cell(2, 0));
      await tester.pump();
      expect(xAt(2, 2), findsNothing);
      expect(xAt(2, 0), findsNothing);
      expect(oAt(2, 2), findsNothing);
      expect(ai.requests, hasLength(requests));

      await tester.pumpAndSettle();
      expect(_overlay, findsOneWidget);
    });

    testWidgets('taps are ignored while the card is up', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      expect(_overlay, findsOneWidget);
      final requests = ai.requests.length;

      await tester.tap(cell(2, 2), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('new-game')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(xAt(2, 2), findsNothing);
      expect(ai.requests, hasLength(requests));
      expect(_overlay, findsOneWidget);
      expect(textOf(tester, 'board-size'), '3 × 3');
    });

    testWidgets('New Game during the line animation cancels the card', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await _setUpWinningTap(tester, ai);

      await tester.tap(cell(0, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('new-game')));
      await tester.pumpAndSettle();

      expect(_overlay, findsNothing);
      expect(xAt(0, 0), findsNothing);
      expect(textOf(tester, 'score-human'), '0');
      expect(textOf(tester, 'turn-label'), 'YOUR TURN');
    });

    testWidgets('coming back to a finished round shows the card at once', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, computerWinTaps, computerWinReplies);
      expect(_overlay, findsOneWidget);

      // The system back button: the card covers the one in the header.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.openGame();
      expect(_overlay, findsOneWidget);
      expect(find.text('RETRY LEVEL'), findsOneWidget);
    });
  });

  group('board change transition', () {
    testWidgets('the old board fades out as the new one comes in', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(GameScreen.boardChangeDuration ~/ 2);
      // Both the 3x3 and the 4x4 are on screen mid-transition.
      expect(find.byType(BoardView), findsNWidgets(2));
      expect(allCells, findsNWidgets(9 + 16));

      await tester.pumpAndSettle();
      expect(find.byType(BoardView), findsOneWidget);
      expect(allCells, findsNWidgets(16));
    });

    testWidgets('New Game also swaps the board', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      ai.script.add(const Position(1, 1));
      await tester.tapCells(const [Position(0, 0)]);

      await tester.tap(find.byKey(const ValueKey('new-game')));
      await tester.pump();
      await tester.pump(GameScreen.boardChangeDuration ~/ 2);
      expect(find.byType(BoardView), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.byType(BoardView), findsOneWidget);
      expect(xAt(0, 0), findsNothing);
    });
  });

  group('reduce motion', () {
    testWidgets('the card appears without waiting for the line', (
      tester,
    ) async {
      _reduceMotion(tester);
      final ai = await pumpApp(tester);
      await tester.openGame();
      await _setUpWinningTap(tester, ai);

      await tester.tap(cell(0, 2));
      await tester.pump();
      await tester.pump();
      expect(_overlay, findsOneWidget);
      // The whole line is there and the card is fully opaque straight away.
      expect(_winLine, findsOneWidget);
      final opacity = find.descendant(
        of: _overlay,
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(opacity.first).opacity, 1);
    });

    testWidgets('the board changes without a transition', (tester) async {
      _reduceMotion(tester);
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump();
      expect(find.byType(BoardView), findsOneWidget);
      expect(allCells, findsNWidgets(16));
    });
  });

  group('accessibility', () {
    testWidgets('every cell has a row, column and contents label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final ai = await pumpApp(tester);
      await tester.openGame();

      for (var row = 1; row <= 3; row++) {
        for (var col = 1; col <= 3; col++) {
          expect(
            find.bySemanticsLabel('Row $row, column $col, empty'),
            findsOneWidget,
          );
        }
      }

      ai.script.add(const Position(1, 2));
      await tester.tapCells(const [Position(0, 0)]);
      expect(find.bySemanticsLabel('Row 1, column 1, X'), findsOneWidget);
      expect(find.bySemanticsLabel('Row 2, column 3, O'), findsOneWidget);
      expect(find.bySemanticsLabel('Row 2, column 3, empty'), findsNothing);
      expect(find.bySemanticsLabel('Row 3, column 3, empty'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('round results are announced', (tester) async {
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final event = message as Map<Object?, Object?>;
            if (event['type'] == 'announce') {
              final data = event['data']! as Map<Object?, Object?>;
              announcements.add(data['message']! as String);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );

      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      expect(announcements, ['You Win. Next level: 4 × 4']);

      await tester.continueFromResult();
      await tester.playRound(
        ai,
        const [Position(0, 0), Position(0, 1), Position(1, 3), Position(2, 0)],
        const [Position(3, 0), Position(3, 1), Position(3, 2), Position(3, 3)],
      );
      expect(announcements.last, 'Computer Wins. Try 4 × 4 again');

      await tester.continueFromResult();
      await tester.playRound(ai, draw4x4Taps, draw4x4Replies);
      expect(announcements.last, 'Draw. Back to 3 × 3');
      expect(announcements, hasLength(3));
    });

    for (final size in const [smallPhone, tallPhone]) {
      testWidgets(
        'text at 200% does not break the header or the result card at '
        '${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final ai = await pumpApp(tester, size: size);
          expect(tester.takeException(), isNull);
          await tester.openGame();
          expect(tester.takeException(), isNull);

          // The header still shows both lines, inside the screen.
          final screen = Offset.zero & size;
          for (final key in ['board-size', 'win-length']) {
            final rect = tester.getRect(find.byKey(ValueKey(key)));
            expect(screen.contains(rect.topLeft), isTrue, reason: key);
            expect(screen.contains(rect.bottomRight), isTrue, reason: key);
          }
          expect(allCells, findsNWidgets(9));

          await tester.playRound(ai, humanWinTaps, humanWinReplies);
          expect(tester.takeException(), isNull);
          expect(textOf(tester, 'result-subtitle'), 'Next level: 4 × 4');
          await tester.continueFromResult();
          expect(textOf(tester, 'board-size'), '4 × 4');

          await tester.playRound(
            ai,
            const [
              Position(0, 0),
              Position(0, 1),
              Position(1, 3),
              Position(2, 0),
            ],
            const [
              Position(3, 0),
              Position(3, 1),
              Position(3, 2),
              Position(3, 3),
            ],
          );
          expect(tester.takeException(), isNull);
          await tester.continueFromResult();

          await tester.playRound(ai, draw4x4Taps, draw4x4Replies);
          expect(tester.takeException(), isNull);
          await tester.continueFromResult();
          expect(textOf(tester, 'board-size'), '3 × 3');
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
