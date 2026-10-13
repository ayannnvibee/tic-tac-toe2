import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

const _sizes = [3, 4, 5, 7];
const _boardsPerCase = 150;

void main() {
  final players = <String, AiPlayer Function(int seed)>{
    for (final difficulty in Difficulty.values)
      difficulty.name: (seed) =>
          GameAi(difficulty: difficulty, random: Random(seed)),
    'medium that always blunders': (seed) =>
        GameAi(random: Random(seed), blunderChance: 1),
    'medium with no time budget': (seed) =>
        GameAi(random: Random(seed), timeBudget: Duration.zero),
  };

  players.forEach((name, create) {
    group(name, () {
      for (final size in _sizes) {
        test('takes an immediate win on ${size}x$size', () {
          final rng = Random(size);
          final ai = create(size);

          for (var i = 0; i < _boardsPerCase; i++) {
            final board = boardWithThreat(rng, size, aiMark);
            final wins = winningCells(board, aiMark);
            expect(wins, isNotEmpty);

            final move = ai.chooseMove(board, aiMark, humanMark);
            expect(wins, contains(move), reason: 'played $move on\n$board');
          }
        });

        test('blocks an immediate human win on ${size}x$size', () {
          final rng = Random(100 + size);
          final ai = create(size);

          var checked = 0;
          while (checked < _boardsPerCase) {
            final board = boardWithThreat(rng, size, humanMark);
            // Only boards where the AI cannot simply win instead.
            if (winningCells(board, aiMark).isNotEmpty) continue;
            final threats = winningCells(board, humanMark);
            expect(threats, isNotEmpty);

            final move = ai.chooseMove(board, aiMark, humanMark);
            expect(threats, contains(move), reason: 'played $move on\n$board');
            checked++;
          }
        });
      }
    });
  });

  test('prefers its own win over blocking', () {
    final board = Board.fromCells(4, const [
      Mark.x, Mark.x, Mark.x, Mark.empty, //
      Mark.o, Mark.o, Mark.o, Mark.empty,
      Mark.empty, Mark.empty, Mark.empty, Mark.empty,
      Mark.empty, Mark.empty, Mark.empty, Mark.empty,
    ]);
    for (final difficulty in Difficulty.values) {
      final ai = GameAi(difficulty: difficulty, random: Random(3));
      expect(ai.chooseMove(board, aiMark, humanMark), const Position(1, 3));
    }
  });

  test('wins and blocks when it plays X', () {
    final rng = Random(9);
    final ai = GameAi(random: Random(9));
    for (var i = 0; i < 100; i++) {
      final board = boardWithThreat(rng, 6, Mark.x);
      final move = ai.chooseMove(board, Mark.x, Mark.o);
      expect(winningCells(board, Mark.x), contains(move));
    }
  });

  group('threats on larger boards', () {
    test('blocks an open three before it becomes an open four', () {
      // X has three in a row with both ends open on 7x7.
      var board = Board.empty(7);
      for (final col in [2, 3, 4]) {
        board = board.place(Position(3, col), Mark.x);
      }
      board = board
          .place(const Position(0, 0), Mark.o)
          .place(const Position(6, 6), Mark.o);

      final move = GameAi(random: Random(1))
          .chooseMove(board, aiMark, humanMark);
      expect(const [Position(3, 1), Position(3, 5)], contains(move));
    });

    test('turns its own open three into an unstoppable four', () {
      var board = Board.empty(7);
      for (final col in [2, 3, 4]) {
        board = board.place(Position(3, col), Mark.o);
      }
      board = board
          .place(const Position(0, 0), Mark.x)
          .place(const Position(6, 6), Mark.x)
          .place(const Position(0, 6), Mark.x);

      final move = GameAi(random: Random(1))
          .chooseMove(board, aiMark, humanMark);
      expect(const [Position(3, 1), Position(3, 5)], contains(move));
      expect(winningCells(board.place(move, Mark.o), Mark.o), hasLength(2));
    });
  });
}
