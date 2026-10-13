import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

const _gamesPerSize = 200;

/// The lowest share of games the simulated human must win, by board size.
/// Sizes without an entry are only measured and printed.
const _minHumanWinRate = <int, double>{3: 0.30, 4: 0.15, 5: 0.15, 6: 0.15};

/// One round of the simulated human against medium.
///
/// The human plays X, moves first, and uses the same engines as the computer
/// with no blunders: perfect play on 3x3 and the full heuristic above that.
RoundStatus _playRound(int size, int seed) {
  final computer = GameAi(random: Random(seed));
  final human = GameAi(
    difficulty: Difficulty.hard,
    random: Random(seed + 100000),
  );

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
