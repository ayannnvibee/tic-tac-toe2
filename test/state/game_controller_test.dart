import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
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

  group('a fresh container', () {
    test('starts at 3x3, 0/0, human to move', () {
      expectInitial(container.game);
      expect(container.game.difficulty, Difficulty.medium);
      expect(container.game.soundEnabled, isTrue);
      expect(container.game.hapticsEnabled, isTrue);
      expect(ai.requests, isEmpty);
    });

    test('does not inherit anything from an earlier container', () async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      container.controller
        ..continueToNextRound()
        ..toggleSound()
        ..toggleHaptics()
        ..setDifficulty(Difficulty.hard);
      expect(container.game.session.boardSize, 4);

      final fresh = createContainer(FakeAi());
      expectInitial(fresh.game);
      expect(fresh.game.difficulty, Difficulty.medium);
      expect(fresh.game.soundEnabled, isTrue);
      expect(fresh.game.hapticsEnabled, isTrue);
    });
  });

  group('human tap', () {
    test('makes the computer reply with exactly one move', () async {
      ai.script.add(const Position(1, 1));
      await container.controller.onCellTapped(const Position(0, 0));

      expect(container.board.cellAt(const Position(0, 0)), Mark.x);
      expect(container.board.cellAt(const Position(1, 1)), Mark.o);
      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 1);
      expect(ai.requests, hasLength(1));
      expect(container.round.currentTurn, Player.human);
      expect(container.game.isAiThinking, isFalse);
      expect(container.game.pendingResult, isNull);
    });

    test('the request describes the board after the human move', () async {
      await container.controller.onCellTapped(const Position(2, 1));

      final request = ai.requests.single;
      expect(request.size, 3);
      expect(request.difficulty, Difficulty.medium);
      expect(request.aiMark, Mark.o);
      expect(
        request.toBoard(),
        Board.empty(3).place(const Position(2, 1), Mark.x),
      );
    });

    test('the chosen difficulty is passed to the engine', () async {
      container.controller.setDifficulty(Difficulty.hard);
      await container.controller.onCellTapped(const Position(0, 0));
      expect(ai.requests.single.difficulty, Difficulty.hard);
    });

    test('taps during the computer turn are ignored', () async {
      ai.hold = true;
      final turn = container.controller.onCellTapped(const Position(0, 0));

      expect(container.game.isAiThinking, isTrue);
      expect(container.board.cellAt(const Position(0, 0)), Mark.x);

      await container.controller.onCellTapped(const Position(1, 1));
      await container.controller.onCellTapped(const Position(2, 2));
      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 0);
      expect(ai.requests, hasLength(1));
      expect(container.game.isAiThinking, isTrue);

      ai.release(0, const Position(1, 1));
      await turn;
      expect(container.board.cellAt(const Position(1, 1)), Mark.o);
      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 1);
      expect(container.game.isAiThinking, isFalse);
    });

    test('an occupied cell is ignored and the computer is not asked', () async {
      ai.script.add(const Position(1, 1));
      await container.controller.onCellTapped(const Position(0, 0));

      await container.controller.onCellTapped(const Position(0, 0));
      await container.controller.onCellTapped(const Position(1, 1));
      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 1);
      expect(ai.requests, hasLength(1));
    });

    test('a cell off the board is ignored', () async {
      await container.controller.onCellTapped(const Position(3, 0));
      await container.controller.onCellTapped(const Position(-1, 2));
      expect(container.board, Board.empty(3));
      expect(ai.requests, isEmpty);
    });

    test('the computer turn takes at least the configured delay', () async {
      final slow = createContainer(
        FakeAi(),
        delay: const Duration(milliseconds: 80),
      );
      final clock = Stopwatch()..start();
      final turn = slow.controller.onCellTapped(const Position(0, 0));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(slow.game.isAiThinking, isTrue);
      expect(countMarks(slow.board, Mark.o), 0);

      await turn;
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(75));
      expect(countMarks(slow.board, Mark.o), 1);
      expect(slow.game.isAiThinking, isFalse);
    });
  });

  group('a broken engine', () {
    test('an illegal answer is replaced by a legal move', () async {
      // The engine answers with the cell the human just took.
      ai.script.add(const Position(0, 0));
      await container.controller.onCellTapped(const Position(0, 0));

      expect(container.board.cellAt(const Position(0, 0)), Mark.x);
      expect(countMarks(container.board, Mark.o), 1);
      expect(container.game.isAiThinking, isFalse);
      expect(container.round.currentTurn, Player.human);
    });

    test('an error still ends the turn with one legal move', () async {
      ai.error = StateError('engine crashed');
      await container.controller.onCellTapped(const Position(1, 1));

      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 1);
      expect(container.game.isAiThinking, isFalse);
    });
  });

  group('human win', () {
    setUp(() async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
    });

    test('keeps the finished board and winning line visible', () {
      expect(container.game.pendingResult, RoundStatus.humanWon);
      expect(container.round.status, RoundStatus.humanWon);
      expect(container.round.winningLine, humanWinTaps);
      expect(container.board.cellAt(const Position(0, 2)), Mark.x);
      // Nothing changes until the UI asks for the next round.
      expect(container.game.session.boardSize, 3);
      expect(container.game.session.humanWins, 0);
      expect(container.game.isAiThinking, isFalse);
      // The computer is not asked to move after the round is over.
      expect(ai.requests, hasLength(2));
    });

    test('taps on the finished board are ignored', () async {
      final finished = container.board;
      await container.controller.onCellTapped(const Position(2, 2));
      expect(container.board, finished);
      expect(ai.requests, hasLength(2));
    });

    test('then continue: board is one larger and only humanWins grows', () {
      container.controller.continueToNextRound();

      final state = container.game;
      expect(state.session.boardSize, 4);
      expect(state.session.humanWins, 1);
      expect(state.session.computerWins, 0);
      expect(state.session.round.board, Board.empty(4));
      expect(state.session.round.currentTurn, Player.human);
      expect(state.session.round.winningLine, isNull);
      expect(state.pendingResult, isNull);
      expect(state.isAiThinking, isFalse);
    });

    test('continuing twice only advances once', () {
      container.controller
        ..continueToNextRound()
        ..continueToNextRound();
      expect(container.game.session.boardSize, 4);
      expect(container.game.session.humanWins, 1);
    });
  });

  group('computer win', () {
    setUp(() async {
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);
    });

    test('keeps the finished board and winning line visible', () {
      expect(container.game.pendingResult, RoundStatus.computerWon);
      expect(container.round.winningLine, computerWinReplies);
      expect(container.game.session.computerWins, 0);
      expect(container.game.isAiThinking, isFalse);
    });

    test('then continue: same size and only computerWins grows', () {
      container.controller.continueToNextRound();

      final state = container.game;
      expect(state.session.boardSize, 3);
      expect(state.session.humanWins, 0);
      expect(state.session.computerWins, 1);
      expect(state.session.round.board, Board.empty(3));
      expect(state.session.round.currentTurn, Player.human);
      expect(state.pendingResult, isNull);
    });

    test('the human level survives a later computer win', () async {
      // Lose on 3x3, win on 3x3, then lose on 4x4.
      container.controller.continueToNextRound();
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      container.controller.continueToNextRound();
      expect(container.game.session.boardSize, 4);

      ai.script.addAll(const [
        Position(3, 0),
        Position(3, 1),
        Position(3, 2),
        Position(3, 3),
      ]);
      await container.tapAll(const [
        Position(0, 0),
        Position(0, 1),
        Position(1, 3),
        Position(2, 0),
      ]);
      expect(container.game.pendingResult, RoundStatus.computerWon);

      container.controller.continueToNextRound();
      expect(container.game.session.boardSize, 4);
      expect(container.game.session.humanWins, 1);
      expect(container.game.session.computerWins, 2);
    });
  });

  group('draw', () {
    test('then continue: 3x3 and 0/0', () async {
      ai.script.addAll(drawReplies);
      await container.tapAll(drawTaps);

      expect(container.game.pendingResult, RoundStatus.draw);
      expect(container.board.isFull, isTrue);
      expect(container.round.winningLine, isNull);

      container.controller.continueToNextRound();
      expectInitial(container.game);
    });

    test('on a larger board also wipes the score and the level', () async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      container.controller.continueToNextRound();
      expect(container.game.session.boardSize, 4);
      expect(container.game.session.humanWins, 1);

      // XXOO / OOXX / XXOO / OOXX has no four in a row.
      ai.script.addAll(const [
        Position(0, 2),
        Position(0, 3),
        Position(1, 0),
        Position(1, 1),
        Position(2, 2),
        Position(2, 3),
        Position(3, 0),
        Position(3, 1),
      ]);
      await container.tapAll(const [
        Position(0, 0),
        Position(0, 1),
        Position(1, 2),
        Position(1, 3),
        Position(2, 0),
        Position(2, 1),
        Position(3, 2),
        Position(3, 3),
      ]);
      expect(container.game.pendingResult, RoundStatus.draw);
      // Still the finished 4x4 board until the UI continues.
      expect(container.game.session.boardSize, 4);
      expect(container.game.session.humanWins, 1);

      container.controller.continueToNextRound();
      expectInitial(container.game);
    });
  });

  group('new game', () {
    test('mid-round resets to 3x3 and 0/0', () async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      container.controller.continueToNextRound();
      await container.tapAll(const [Position(0, 0), Position(2, 2)]);
      expect(container.game.session.boardSize, 4);
      expect(countMarks(container.board, Mark.x), 2);

      container.controller.newGame();
      expectInitial(container.game);
    });

    test('on a finished round clears the pending result', () async {
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);
      expect(container.game.pendingResult, RoundStatus.computerWon);

      container.controller.newGame();
      expectInitial(container.game);
    });

    test('while the computer is thinking discards the late move', () async {
      ai.hold = true;
      final turn = container.controller.onCellTapped(const Position(0, 0));
      expect(container.game.isAiThinking, isTrue);

      container.controller.newGame();
      expectInitial(container.game);

      ai.release(0, const Position(1, 1));
      await turn;
      expectInitial(container.game);
      expect(container.board, Board.empty(3));
    });

    test('a late move cannot land in the next game', () async {
      ai.hold = true;
      final first = container.controller.onCellTapped(const Position(0, 0));
      container.controller.newGame();

      // The human is already playing the new game when the old move arrives.
      final second = container.controller.onCellTapped(const Position(2, 2));
      expect(ai.requests, hasLength(2));

      ai.release(0, const Position(1, 1));
      await first;
      expect(container.board.cellAt(const Position(1, 1)), Mark.empty);
      expect(countMarks(container.board, Mark.o), 0);
      expect(container.game.isAiThinking, isTrue);

      ai.release(1, const Position(0, 1));
      await second;
      expect(container.board.cellAt(const Position(0, 1)), Mark.o);
      expect(container.board.cellAt(const Position(2, 2)), Mark.x);
      expect(countMarks(container.board, Mark.x), 1);
      expect(countMarks(container.board, Mark.o), 1);
      expect(container.game.isAiThinking, isFalse);
    });

    test('keeps difficulty, sound and haptics', () {
      container.controller
        ..setDifficulty(Difficulty.easy)
        ..toggleSound()
        ..newGame();
      expect(container.game.difficulty, Difficulty.easy);
      expect(container.game.soundEnabled, isFalse);
      expect(container.game.hapticsEnabled, isTrue);
    });
  });

  test('a disposed game ignores a late computer move', () async {
    final local = FakeAi()..hold = true;
    final disposable = createContainer(local);
    final turn = disposable.controller.onCellTapped(const Position(0, 0));

    disposable.dispose();
    local.release(0, const Position(1, 1));
    await expectLater(turn, completes);
  });

  group('seeds', () {
    test('each AI call gets a different seed', () async {
      for (var game = 0; game < 30; game++) {
        await container.tapAll(const [
          Position(2, 2),
          Position(2, 1),
          Position(1, 2),
        ]);
        container.controller.newGame();
      }

      final seeds = [for (final request in ai.requests) request.seed];
      expect(seeds.length, greaterThanOrEqualTo(60));
      expect(seeds.toSet(), hasLength(seeds.length));
    });

    test('seeds come from the injected generator', () async {
      Future<List<int>> seedsFor(int seed) async {
        final fake = FakeAi();
        final local = createContainer(fake, seed: seed);
        await local.tapAll(const [Position(2, 2), Position(2, 1)]);
        return [for (final request in fake.requests) request.seed];
      }

      expect(await seedsFor(7), await seedsFor(7));
      expect(await seedsFor(7), isNot(await seedsFor(8)));
    });
  });

  group('settings', () {
    test('toggleSound and toggleHaptics flip only their own flag', () {
      container.controller.toggleSound();
      expect(container.game.soundEnabled, isFalse);
      expect(container.game.hapticsEnabled, isTrue);

      container.controller.toggleHaptics();
      expect(container.game.soundEnabled, isFalse);
      expect(container.game.hapticsEnabled, isFalse);

      container.controller
        ..toggleSound()
        ..toggleHaptics();
      expect(container.game.soundEnabled, isTrue);
      expect(container.game.hapticsEnabled, isTrue);
    });
  });

  group('with the real engine', () {
    test('the default AI runs in an isolate and replies legally', () async {
      final real = ProviderContainer.test(
        overrides: [aiMoveDelayProvider.overrideWithValue(Duration.zero)],
      );
      real.listen(gameControllerProvider, (_, _) {});

      await real.controller.onCellTapped(const Position(1, 1));
      expect(countMarks(real.board, Mark.x), 1);
      expect(countMarks(real.board, Mark.o), 1);
      expect(real.game.isAiThinking, isFalse);
    });

    test('the default delay is about 300 ms', () {
      final defaults = ProviderContainer.test();
      expect(
        defaults.read(aiMoveDelayProvider),
        const Duration(milliseconds: 300),
      );
    });
  });
}
