import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

const _gamesPerSize = 200;

/// The lowest share of games the simulated human must win, by board size.
const _minHumanWinRate = <int, double>{
  3: 0.30,
  4: 0.30,
  5: 0.30,
  6: 0.25,
  7: 0.25,
  8: 0.25,
};

/// A player who sees the board well but slips now and then: on 4x4 and
/// larger the first player can force a win, so a flawless simulated human
/// would win every game whatever the computer does.
const _realisticHuman = DifficultyTuning(
  blunderChance: 0.3,
  blunderPool: 4,
  lineDefence: 0.5,
);

/// One round of the simulated human against medium.
///
/// The human plays X and moves first. On 3x3 it plays perfectly; on larger
/// boards it uses the heuristic engine with [_realisticHuman] mistakes.
RoundStatus _playRound(int size, int seed) {
  final computer = GameAi(random: Random(seed));
  final human = size == 3
      ? GameAi(difficulty: Difficulty.hard, random: Random(seed + 100000))
      : GameAi(random: Random(seed + 100000), tuning: _realisticHuman);

  var round = RoundState.initial(size);
  while (!round.isOver) {
    final move = round.currentTurn == Player.human
        ? human.chooseMove(round.board, Mark.x, Mark.o)
        : computer.chooseMove(round.board, Mark.o, Mark.x);
    round = (round.applyMove(move) as MoveAccepted).state;
  }
  return round.status;
}

String _percent(int count) =>
    '${(count * 100 / _gamesPerSize).toStringAsFixed(1)}%';

void main() {
  group('a simulated human can beat medium often enough to progress', () {
    for (final size in [3, 4, 5, 6, 7, 8]) {
      test('${size}x$size over $_gamesPerSize seeded games', () {
        final results = <RoundStatus, int>{
          RoundStatus.humanWon: 0,
          RoundStatus.computerWon: 0,
          RoundStatus.draw: 0,
        };
        for (var seed = 0; seed < _gamesPerSize; seed++) {
          final status = _playRound(size, seed);
          results[status] = results[status]! + 1;
        }

        final humanWins = results[RoundStatus.humanWon]!;
        // Shown in the test output so the rates can be copied into CLAUDE.md.
        // ignore: avoid_print
        print(
          'balance ${size}x$size: human wins ${_percent(humanWins)}, '
          'draws ${_percent(results[RoundStatus.draw]!)}, '
          'computer wins ${_percent(results[RoundStatus.computerWon]!)}',
        );

        final minimum = _minHumanWinRate[size];
        if (minimum != null) {
          expect(humanWins / _gamesPerSize, greaterThanOrEqualTo(minimum));
        }
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });
}
