import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import 'fake_ai.dart';

void main() {
  late FakeAi ai;
  late ProviderContainer container;

  setUp(() {
    ai = FakeAi();
    container = createContainer(ai);
  });

  test('board size, win length and score follow the session', () async {
    expect(container.read(boardSizeProvider), 3);
    expect(container.read(winLengthProvider), 3);
    expect(container.read(scoreProvider), (humanWins: 0, computerWins: 0));

    ai.script.addAll(humanWinReplies);
    await container.tapAll(humanWinTaps);
    // The score only changes when the next round starts.
    expect(container.read(scoreProvider), (humanWins: 0, computerWins: 0));

    container.controller.continueToNextRound();
    expect(container.read(boardSizeProvider), 4);
    expect(container.read(winLengthProvider), 3);
    expect(container.read(scoreProvider), (humanWins: 1, computerWins: 0));

    container.controller.newGame();
    expect(container.read(boardSizeProvider), 3);
    expect(container.read(scoreProvider), (humanWins: 0, computerWins: 0));
  });

  test('win length stops at 5 on large boards', () async {
    for (var size = 3; size < 7; size++) {
      // Win the top row of whatever board is in play.
      final length = winLengthFor(size);
      final taps = [for (var col = 0; col < length; col++) Position(0, col)];
      ai.script.addAll([
        for (var col = 0; col < length - 1; col++) Position(size - 1, col),
      ]);
      await container.tapAll(taps);
      expect(container.game.pendingResult, RoundStatus.humanWon);
      container.controller.continueToNextRound();
    }

    expect(container.read(boardSizeProvider), 7);
    expect(container.read(winLengthProvider), 5);
    expect(container.read(scoreProvider), (humanWins: 4, computerWins: 0));
  });

  group('turn label', () {
    test('your turn, then thinking, then your turn again', () async {
      expect(container.read(turnLabelProvider), 'Your turn');

      ai.hold = true;
      final turn = container.controller.onCellTapped(const Position(0, 0));
      expect(container.read(turnLabelProvider), 'Computer is thinking...');

      ai.release(0, const Position(1, 1));
      await turn;
      expect(container.read(turnLabelProvider), 'Your turn');
    });

    test('You Win until the next round starts', () async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      expect(container.read(turnLabelProvider), 'You Win');

      container.controller.continueToNextRound();
      expect(container.read(turnLabelProvider), 'Your turn');
    });

    test('Computer Wins', () async {
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);
      expect(container.read(turnLabelProvider), 'Computer Wins');
    });

    test('Draw', () async {
      ai.script.addAll(drawReplies);
      await container.tapAll(drawTaps);
      expect(container.read(turnLabelProvider), 'Draw');
    });

    test('New Game while thinking goes straight back to your turn', () {
      ai.hold = true;
      container.controller.onCellTapped(const Position(0, 0));
      expect(container.read(turnLabelProvider), 'Computer is thinking...');

      container.controller.newGame();
      expect(container.read(turnLabelProvider), 'Your turn');
    });
  });

  test('derived providers only notify when their value changes', () async {
    var sizeChanges = 0;
    var scoreChanges = 0;
    container
      ..listen(boardSizeProvider, (_, _) => sizeChanges++)
      ..listen(scoreProvider, (_, _) => scoreChanges++);

    await container.tapAll(const [Position(2, 2), Position(2, 1)]);
    container.controller.toggleSound();
    expect(sizeChanges, 0);
    expect(scoreChanges, 0);
  });
}
