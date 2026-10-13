import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

/// The ceiling for one move on a large board.
const _budget = Duration(milliseconds: 150);

class _Timings {
  final List<int> micros = [];

  void add(Duration elapsed) => micros.add(elapsed.inMicroseconds);

  double get maxMs => micros.reduce(max) / 1000;
  double get averageMs => micros.reduce((a, b) => a + b) / micros.length / 1000;
}

Position _timed(AiPlayer ai, Board board, Mark mine, Mark theirs, _Timings t) {
  final clock = Stopwatch()..start();
  final move = ai.chooseMove(board, mine, theirs);
  t.add(clock.elapsed);
  return move;
}

/// Times every move of games the engine plays against itself, then moves on
/// random boards from nearly empty to nearly full.
_Timings _measure(int size) {
  final timings = _Timings();

  for (var seed = 0; seed < 4; seed++) {
    final ai = GameAi(random: Random(seed));
    var round = RoundState.initial(size);
    // A random opening so the games differ.
    final opening = Random(seed);
    round = (round.applyMove(
      Position(opening.nextInt(size), opening.nextInt(size)),
    ) as MoveAccepted).state;
    while (!round.isOver) {
      final mine = round.currentTurn.mark;
      final theirs = round.currentTurn.opponent.mark;
      final move = _timed(ai, round.board, mine, theirs, timings);
      round = (round.applyMove(move) as MoveAccepted).state;
    }
  }

  final rng = Random(size);
  final ai = GameAi(random: Random(size));
  for (var i = 0; i < 60; i++) {
    final board = randomBoard(rng, size, rng.nextInt(size * size));
    if (board.isFull) continue;
    _timed(ai, board, aiMark, humanMark, timings);
  }
  return timings;
}

void main() {
  setUpAll(() {
    // Let the JIT warm up so the first timed move is not an outlier.
    _measure(8);
  });

  for (final size in [10, 12]) {
    test('${size}x$size moves finish within ${_budget.inMilliseconds} ms', () {
      final timings = _measure(size);

      // Shown in the test output so the numbers can be reported.
      // ignore: avoid_print
      print(
        '${size}x$size: ${timings.micros.length} moves, '
        'max ${timings.maxMs.toStringAsFixed(2)} ms, '
        'average ${timings.averageMs.toStringAsFixed(2)} ms',
      );

      expect(timings.micros.length, greaterThan(60));
      expect(timings.maxMs, lessThan(_budget.inMilliseconds));
    });
  }

  test('the time guard falls back to the heuristic move', () {
    final rng = Random(4);
    final guarded = HeuristicAi(random: Random(4), timeBudget: Duration.zero);
    for (var i = 0; i < 50; i++) {
      final board = randomBoard(rng, 10, rng.nextInt(90));
      final move = guarded.chooseMove(board, aiMark, humanMark);
      expect(board.isEmpty(move), isTrue);
    }
  });

  test('the default time budget leaves room under the ceiling', () {
    expect(aiTimeBudget, lessThan(_budget));
  });
}
