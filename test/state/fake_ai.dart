import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

/// A stand-in for the engine that records every request.
///
/// It answers with the next move in [script], or the first empty cell when
/// the script is empty. With [hold] set it does not answer until [release].
class FakeAi {
  final List<AiRequest> requests = [];
  final Queue<Position> script = Queue();
  final List<Completer<Position>> _held = [];

  bool hold = false;

  /// Thrown instead of answering, when set.
  Object? error;

  Future<Position> call(AiRequest request) {
    requests.add(request);
    if (error != null) throw error!;
    if (hold) {
      final completer = Completer<Position>();
      _held.add(completer);
      return completer.future;
    }
    return Future.value(
      script.isNotEmpty
          ? script.removeFirst()
          : request.toBoard().emptyCells.first,
    );
  }

  /// Answers the [index]th held request with [move].
  void release(int index, Position move) => _held[index].complete(move);
}

/// Records the effects it is asked to play instead of playing them.
class FakeAudio implements AudioService {
  final List<SoundEffect> played = [];
  int preloads = 0;
  bool disposed = false;

  @override
  Future<void> preload() async => preloads++;

  @override
  void play(SoundEffect effect) => played.add(effect);

  @override
  Future<void> dispose() async => disposed = true;
}

/// Records haptics instead of buzzing.
class FakeHaptics implements HapticsService {
  final List<String> events = [];

  @override
  void selectionClick() => events.add('selectionClick');

  @override
  void mediumImpact() => events.add('mediumImpact');
}

ProviderContainer createContainer(
  FakeAi ai, {
  Duration delay = Duration.zero,
  int seed = 1,
  FakeAudio? audio,
  FakeHaptics? haptics,
}) {
  final container = ProviderContainer.test(
    overrides: [
      aiMoveFunctionProvider.overrideWithValue(ai.call),
      aiMoveDelayProvider.overrideWithValue(delay),
      aiSeedRandomProvider.overrideWithValue(Random(seed)),
      audioServiceProvider.overrideWithValue(audio ?? FakeAudio()),
      hapticsServiceProvider.overrideWithValue(haptics ?? FakeHaptics()),
    ],
  );
  // Keep the game alive for the whole test, as the UI will.
  container.listen(gameControllerProvider, (_, _) {});
  return container;
}

extension GameContainer on ProviderContainer {
  GameController get controller => read(gameControllerProvider.notifier);
  GameState get game => read(gameControllerProvider);
  RoundState get round => game.session.round;
  Board get board => round.board;

  /// Taps each of [cells] in turn, waiting for the computer's reply each time.
  Future<void> tapAll(List<Position> cells) async {
    for (final cell in cells) {
      await controller.onCellTapped(cell);
    }
  }
}

int countMarks(Board board, Mark mark) =>
    board.cells.where((cell) => cell == mark).length;

void expectInitial(GameState state) {
  expect(state.session.boardSize, 3);
  expect(state.session.humanWins, 0);
  expect(state.session.computerWins, 0);
  expect(state.session.round.board, Board.empty(3));
  expect(state.session.round.currentTurn, Player.human);
  expect(state.session.round.status, RoundStatus.inProgress);
  expect(state.isAiThinking, isFalse);
  expect(state.pendingResult, isNull);
}

/// Human moves that win the top row of a 3x3 board, with the computer's
/// scripted replies on the middle row.
const humanWinTaps = [Position(0, 0), Position(0, 1), Position(0, 2)];
const humanWinReplies = [Position(1, 0), Position(1, 1)];

/// Human moves that let the computer take the middle row of a 3x3 board.
const computerWinTaps = [Position(0, 0), Position(0, 1), Position(2, 2)];
const computerWinReplies = [Position(1, 0), Position(1, 1), Position(1, 2)];

/// A full 3x3 board with no winner.
const drawTaps = [
  Position(0, 0),
  Position(0, 2),
  Position(2, 1),
  Position(1, 2),
  Position(2, 0),
];
const drawReplies = [
  Position(1, 1),
  Position(0, 1),
  Position(1, 0),
  Position(2, 2),
];
