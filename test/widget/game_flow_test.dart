import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/ui/screens/game_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/home_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/how_to_play_screen.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/result_overlay.dart';

import 'app_harness.dart';

void main() {
  group('Home', () {
    testWidgets('shows the title, Play, How to Play and the sound toggle', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('TIC TAC TOE'), findsOneWidget);
      expect(find.text('INFINITY'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('SFX ON'), findsOneWidget);
    });

    testWidgets('navigates to Game', (tester) async {
      await pumpApp(tester);
      await tester.openGame();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(textOf(tester, 'board-size'), '3 × 3');
      expect(textOf(tester, 'win-length'), 'Get 3 in a row');
      expect(textOf(tester, 'turn-label'), 'YOUR TURN');
      expect(allCells, findsNWidgets(9));
    });

    testWidgets('navigates to How to Play and back', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('how-to-play')));
      await tester.pumpAndSettle();

      expect(find.byType(HowToPlayScreen), findsOneWidget);
      expect(find.text('Beat the computer to grow the board.'), findsOneWidget);
      expect(find.text('You replay the same board size.'), findsOneWidget);
      expect(
        find.text('You start over at 3×3 with the score at 0–0.'),
        findsOneWidget,
      );
      expect(find.text('You need 3 in a row.'), findsOneWidget);
      expect(find.text('You need 4 in a row.'), findsOneWidget);
      expect(
        find.text('You need 5 in a row, however big it gets.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('guide-done')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HowToPlayScreen), findsNothing);
    });

    testWidgets('the sound toggle flips the setting everywhere', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('home-sound-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('MUTED'), findsOneWidget);
      expect(find.text('SFX ON'), findsNothing);

      // The same setting drives the switch on the guide's controls tab.
      await tester.tap(find.byKey(const ValueKey('how-to-play')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab-controls')));
      await tester.pumpAndSettle();
      Switch soundSwitch() =>
          tester.widget<Switch>(find.byKey(const ValueKey('switch-sound')));
      expect(soundSwitch().value, isFalse);
      expect(
        tester
            .widget<Switch>(find.byKey(const ValueKey('switch-haptics')))
            .value,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('switch-sound')));
      await tester.pumpAndSettle();
      expect(soundSwitch().value, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('SFX ON'), findsOneWidget);
    });
  });

  group('Game', () {
    testWidgets(
      'tapping a cell shows an X and the computer answers with an O',
      (tester) async {
        final ai = await pumpApp(tester);
        await tester.openGame();
        expect(xAt(0, 0), findsNothing);

        ai.script.add(const Position(1, 1));
        await tester.tapCells(const [Position(0, 0)]);

        expect(xAt(0, 0), findsOneWidget);
        expect(oAt(1, 1), findsOneWidget);
        expect(textOf(tester, 'turn-label'), 'YOUR TURN');
      },
    );

    testWidgets('a taken cell cannot be tapped again', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      ai.script.add(const Position(1, 1));
      await tester.tapCells(const [Position(0, 0), Position(1, 1)]);

      expect(oAt(1, 1), findsOneWidget);
      expect(xAt(1, 1), findsNothing);
      expect(ai.requests, hasLength(1));
    });

    testWidgets('shows the thinking label while the computer decides', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      ai.hold = true;
      await tester.tapCells(const [Position(0, 0)]);

      expect(textOf(tester, 'turn-label'), 'COMPUTER IS THINKING...');
      // A second tap while it thinks does nothing.
      await tester.tapCells(const [Position(2, 2)]);
      expect(xAt(2, 2), findsNothing);

      ai.release(0, const Position(1, 1));
      await tester.pumpAndSettle();
      expect(oAt(1, 1), findsOneWidget);
      expect(textOf(tester, 'turn-label'), 'YOUR TURN');
    });

    testWidgets('New Game resets the counters to 0/0 and the board to 3×3', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();

      // Win a round so there is a score and a bigger board to reset.
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      await tester.tap(find.byKey(const ValueKey('result-continue')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(textOf(tester, 'win-length'), 'Get 3 in a row');
      expect(textOf(tester, 'score-human'), '1');
      expect(allCells, findsNWidgets(16));

      await tester.tapCells(const [Position(0, 0)]);
      expect(xAt(0, 0), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('new-game')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'board-size'), '3 × 3');
      expect(textOf(tester, 'win-length'), 'Get 3 in a row');
      expect(textOf(tester, 'score-human'), '0');
      expect(textOf(tester, 'score-computer'), '0');
      expect(allCells, findsNWidgets(9));
      expect(xAt(0, 0), findsNothing);
    });

    testWidgets('back returns Home and keeps the session alive', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      await tester.tap(find.byKey(const ValueKey('result-continue')));
      await tester.pumpAndSettle();
      await tester.tapCells(const [Position(3, 3)]);

      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('4×4 Board • Get 3 in a row'), findsOneWidget);

      await tester.openGame();
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(textOf(tester, 'score-human'), '1');
      expect(xAt(3, 3), findsOneWidget);
    });
  });

  group('Round results', () {
    testWidgets('a human win shows Next Level and grows the board', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      expect(find.byType(ResultOverlay), findsNothing);

      await tester.playRound(ai, humanWinTaps, humanWinReplies);

      expect(find.byType(ResultOverlay), findsOneWidget);
      expect(find.text('YOU WIN!'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsOneWidget);
      expect(find.text('RETRY LEVEL'), findsNothing);
      expect(find.text('RESTART'), findsNothing);
      expect(textOf(tester, 'turn-label'), 'YOU WIN');
      // The finished board is still there underneath.
      expect(xAt(0, 2), findsOneWidget);
      expect(textOf(tester, 'board-size'), '3 × 3');

      await tester.tap(find.text('NEXT LEVEL'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultOverlay), findsNothing);
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(textOf(tester, 'score-human'), '1');
      expect(textOf(tester, 'score-computer'), '0');
    });

    testWidgets('a computer win shows Retry Level and keeps the size', (
      tester,
    ) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, computerWinTaps, computerWinReplies);

      expect(find.text('COMPUTER WINS!'), findsOneWidget);
      expect(find.text('RETRY LEVEL'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('RESTART'), findsNothing);
      expect(textOf(tester, 'turn-label'), 'COMPUTER WINS');

      await tester.tap(find.text('RETRY LEVEL'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultOverlay), findsNothing);
      expect(textOf(tester, 'board-size'), '3 × 3');
      expect(textOf(tester, 'score-human'), '0');
      expect(textOf(tester, 'score-computer'), '1');
      expect(oAt(1, 1), findsNothing);
    });

    testWidgets('a draw shows Restart and resets everything', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      // Reach 4x4 with a score first, so the reset is visible.
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      await tester.tap(find.text('NEXT LEVEL'));
      await tester.pumpAndSettle();

      // XXOO / OOXX / XXOO / OOXX has no three in a row.
      await tester.playRound(
        ai,
        const [
          Position(0, 0),
          Position(0, 1),
          Position(1, 2),
          Position(1, 3),
          Position(2, 0),
          Position(2, 1),
          Position(3, 2),
          Position(3, 3),
        ],
        const [
          Position(0, 2),
          Position(0, 3),
          Position(1, 0),
          Position(1, 1),
          Position(2, 2),
          Position(2, 3),
          Position(3, 0),
          Position(3, 1),
        ],
      );

      expect(find.text("IT'S A DRAW!"), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('RETRY LEVEL'), findsNothing);
      expect(textOf(tester, 'turn-label'), 'DRAW');

      await tester.tap(find.text('RESTART'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultOverlay), findsNothing);
      expect(textOf(tester, 'board-size'), '3 × 3');
      expect(textOf(tester, 'score-human'), '0');
      expect(textOf(tester, 'score-computer'), '0');
      expect(allCells, findsNWidgets(9));
    });

    testWidgets('the board cannot be tapped behind a result', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);

      await tester.tap(cell(2, 2), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(xAt(2, 2), findsNothing);
      expect(find.byType(ResultOverlay), findsOneWidget);
    });
  });

  group('layout', () {
    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(820, 1180),
    ]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('every screen lays out at ${size.width.toInt()}x'
            '${size.height.toInt()} in ${mode.name} mode', (tester) async {
          final ai = await pumpApp(tester, size: size, themeMode: mode);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(const ValueKey('how-to-play')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('tab-controls')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();

          await tester.openGame();
          expect(tester.takeException(), isNull);

          await tester.playRound(ai, computerWinTaps, computerWinReplies);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('result-continue')));
          await tester.pumpAndSettle();

          await tester.playRound(ai, drawTaps, drawReplies);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('result-continue')));
          await tester.pumpAndSettle();

          await tester.playRound(ai, humanWinTaps, humanWinReplies);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('result-continue')));
          await tester.pumpAndSettle();
          expect(textOf(tester, 'board-size'), '4 × 4');
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
