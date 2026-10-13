import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

/// Results of playing every possible human move sequence against [ai].
class _Outcomes {
  int humanWins = 0;
  int aiWins = 0;
  int draws = 0;

  int get games => humanWins + aiWins + draws;
}

void _humanToMove(AiPlayer ai, Board board, _Outcomes outcomes) {
  for (final cell in board.emptyCells) {
    final afterHuman = board.place(cell, humanMark);
    if (winChecker.winningLineFrom(afterHuman, cell) != null) {
      outcomes.humanWins++;
    } else if (afterHuman.isFull) {
      outcomes.draws++;
    } else {
      _aiToMove(ai, afterHuman, outcomes);
    }
  }
}

void _aiToMove(AiPlayer ai, Board board, _Outcomes outcomes) {
  final move = ai.chooseMove(board, aiMark, humanMark);
  final afterAi = board.place(move, aiMark);
  if (winChecker.winningLineFrom(afterAi, move) != null) {
    outcomes.aiWins++;
  } else if (afterAi.isFull) {
    outcomes.draws++;
  } else {
    _humanToMove(ai, afterAi, outcomes);
  }
}

void main() {
  group('hard 3x3 never loses', () {
    for (final seed in [0, 1, 2, 3]) {
      test('human moves first, seed $seed', () {
        final ai = GameAi(difficulty: Difficulty.hard, random: Random(seed));
        final outcomes = _Outcomes();
        _humanToMove(ai, Board.empty(3), outcomes);

        expect(outcomes.humanWins, 0);
        expect(outcomes.games, greaterThan(100));
        expect(outcomes.aiWins, greaterThan(0));
      });

      test('computer moves first, seed $seed', () {
        final ai = GameAi(difficulty: Difficulty.hard, random: Random(seed));
        final outcomes = _Outcomes();
        _aiToMove(ai, Board.empty(3), outcomes);

        expect(outcomes.humanWins, 0);
        expect(outcomes.games, greaterThan(10));
      });
    }
  });

  group('medium 3x3', () {
    test('with no blunder chance it never loses', () {
      final ai = GameAi(random: Random(5), blunderChance: 0);
      final outcomes = _Outcomes();
      _humanToMove(ai, Board.empty(3), outcomes);
      expect(outcomes.humanWins, 0);
    });

    test('with blunders the human can win', () {
      var humanWins = 0;
      for (var seed = 0; seed < 10; seed++) {
        final ai = GameAi(random: Random(seed), blunderChance: 1);
        final outcomes = _Outcomes();
        _humanToMove(ai, Board.empty(3), outcomes);
        humanWins += outcomes.humanWins;
      }
      expect(humanWins, greaterThan(0));
    });

    test('the default blunder chance is 15%', () {
      expect(MinimaxAi.defaultBlunderChance, 0.15);
      expect(MinimaxAi().blunderChance, 0.15);
    });

    test('a blunder never hands over an immediate win', () {
      // X threatens the top row; every blunder must still block at (0, 2).
      final board = Board.empty(3)
          .place(const Position(0, 0), Mark.x)
          .place(const Position(1, 1), Mark.o)
          .place(const Position(0, 1), Mark.x);
      for (var seed = 0; seed < 50; seed++) {
        final ai = GameAi(random: Random(seed), blunderChance: 1);
        expect(ai.chooseMove(board, aiMark, humanMark), const Position(0, 2));
      }
    });
  });

  test('minimax refuses boards larger than 3x3', () {
    expect(
      () => MinimaxAi().chooseMove(Board.empty(4), aiMark, humanMark),
      throwsArgumentError,
    );
  });
}
