import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/app.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import '../state/fake_ai.dart';

export '../state/fake_ai.dart';

/// A typical phone in portrait, in logical pixels.
const Size phoneSize = Size(390, 844);

/// The surfaces the layout is checked on: a small phone, a tall phone and a
/// 7-inch tablet, all in logical pixels.
const Size smallPhone = Size(360, 640);
const Size tallPhone = Size(412, 915);
const Size sevenInchTablet = Size(600, 960);

/// A controller whose session starts on a board of [boardSize], as if the
/// human had already won their way up to it.
class SizedGameController extends GameController {
  SizedGameController(this.boardSize);

  final int boardSize;

  @override
  GameState build() => super.build().copyWith(
    session: Session(
      boardSize: boardSize,
      humanWins: boardSize - initialBoardSize,
      computerWins: 0,
      round: RoundState.initial(boardSize),
    ),
  );
}

/// Pumps the whole app with a scripted computer, no move delay and fake
/// sound and haptics.
Future<FakeAi> pumpApp(
  WidgetTester tester, {
  Size size = phoneSize,
  ThemeMode themeMode = ThemeMode.light,
  FakeAudio? audio,
  FakeHaptics? haptics,
  int? boardSize,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final ai = FakeAi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiMoveFunctionProvider.overrideWithValue(ai.call),
        aiMoveDelayProvider.overrideWithValue(Duration.zero),
        aiSeedRandomProvider.overrideWithValue(Random(1)),
        audioServiceProvider.overrideWithValue(audio ?? FakeAudio()),
        hapticsServiceProvider.overrideWithValue(haptics ?? FakeHaptics()),
        if (boardSize != null)
          gameControllerProvider.overrideWith(
            () => SizedGameController(boardSize),
          ),
      ],
      child: TicTacToeInfinityApp(themeMode: themeMode),
    ),
  );
  await tester.pumpAndSettle();
  return ai;
}

Finder cell(int row, int col) => find.byKey(ValueKey('cell-$row-$col'));
Finder xAt(int row, int col) => find.byKey(ValueKey('mark-x-$row-$col'));
Finder oAt(int row, int col) => find.byKey(ValueKey('mark-o-$row-$col'));

/// Every cell on the board, whatever its size.
Finder get allCells => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith('cell-');
});

final Finder zoomControls = find.byKey(const ValueKey('zoom-controls'));
final Finder boardViewer = find.byKey(const ValueKey('board-viewer'));
final Finder continueButton = find.byKey(const ValueKey('result-continue'));

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

extension AppActions on WidgetTester {
  Future<void> openGame() async {
    await ensureVisible(find.byKey(const ValueKey('play')));
    await tap(find.byKey(const ValueKey('play')));
    await pumpAndSettle();
  }

  /// Taps each cell in turn, letting the computer reply after each one.
  Future<void> tapCells(List<Position> cells) async {
    for (final position in cells) {
      await tap(cell(position.row, position.col));
      await pumpAndSettle();
    }
  }

  /// Plays a scripted round: the human taps [taps], the computer answers
  /// with [replies].
  Future<void> playRound(
    FakeAi ai,
    List<Position> taps,
    List<Position> replies,
  ) async {
    ai.script.addAll(replies);
    await tapCells(taps);
  }

  /// Presses the single button on the result card.
  Future<void> continueFromResult() async {
    await ensureVisible(continueButton);
    await tap(continueButton);
    await pumpAndSettle();
  }
}

/// A full 4x4 board with no four in a row: XXOO / OOXX / XXOO / OOXX.
const draw4x4Taps = [
  Position(0, 0),
  Position(0, 1),
  Position(1, 2),
  Position(1, 3),
  Position(2, 0),
  Position(2, 1),
  Position(3, 2),
  Position(3, 3),
];
const draw4x4Replies = [
  Position(0, 2),
  Position(0, 3),
  Position(1, 0),
  Position(1, 1),
  Position(2, 2),
  Position(2, 3),
  Position(3, 0),
  Position(3, 1),
];
