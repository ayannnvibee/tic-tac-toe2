import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

const _sizes = [3, 4, 5, 7];
const _boardsPerCase = 150;

/// The share of immediate human threats medium must still block.
const _minMediumBlockRate = 0.7;

/// A board where the human is one move from winning and the AI cannot simply
/// win instead, with the cells that would block it.
(Board, Set<Position>) _threatBoard(Random rng, int size) {
  while (true) {
    final board = boardWithThreat(rng, size, humanMark);
    if (winningCells(board, aiMark).isNotEmpty) continue;
    return (board, winningCells(board, humanMark));
  }
}

void main() {
  // Every one of these takes an immediate win.
  final players = <String, AiPlayer Function(int seed)>{
    for (final difficulty in Difficulty.values)
      difficulty.name: (seed) =>
          GameAi(difficulty: difficulty, random: Random(seed)),
    'medium that always blunders': (seed) =>
        GameAi(random: Random(seed), tuning: alwaysBlunder),
    'medium with no time budget': (seed) =>
        GameAi(random: Random(seed), timeBudget: Duration.zero),
  };

  // These never blunder, so they also block every immediate human win.
  final blockers = <String, AiPlayer Function(int seed)>{
    'easy': (seed) => GameAi(difficulty: Difficulty.easy, random: Random(seed)),
    'hard': (seed) => GameAi(difficulty: Difficulty.hard, random: Random(seed)),
    'medium without blunders': (seed) =>
        GameAi(random: Random(seed), tuning: noBlunders),
    'hard with no time budget': (seed) => GameAi(
      difficulty: Difficulty.hard,
      random: Random(seed),
      timeBudget: Duration.zero,
    ),
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
      }
    });
  });

  blockers.forEach((name, create) {
    group(name, () {
      for (final size in _sizes) {
        test('blocks an immediate human win on ${size}x$size', () {
          final rng = Random(100 + size);
          final ai = create(size);

          for (var i = 0; i < _boardsPerCase; i++) {
            final (board, threats) = _threatBoard(rng, size);
            expect(threats, isNotEmpty);

            final move = ai.chooseMove(board, aiMark, humanMark);
            expect(threats, contains(move), reason: 'played $move on\n$board');
          }
        });
      }
    });
  });

  group('medium with its default blunders', () {
    for (final size in [4, 5, 6, 7, 10]) {
      test('still blocks most immediate human wins on ${size}x$size', () {
        final rng = Random(200 + size);
        final ai = GameAi(random: Random(size));
        const boards = 1000;

        var blocked = 0;
        for (var i = 0; i < boards; i++) {
          final (board, threats) = _threatBoard(rng, size);
          if (threats.contains(ai.chooseMove(board, aiMark, humanMark))) {
            blocked++;
          }
        }

        final rate = blocked / boards;
        // Shown in the test output so the numbers can be reported.
        // ignore: avoid_print
        print(
          '${size}x$size medium blocks '
          '${(rate * 100).toStringAsFixed(1)}% of immediate threats',
        );
        expect(rate, greaterThanOrEqualTo(_minMediumBlockRate));
        // It does blunder, so it must not be perfect either.
        expect(rate, lessThan(1));
      });
    }
  });

  test('prefers its own win over blocking', () {
    final board = Board.fromCells(4, const [
      Mark.x, Mark.x, Mark.empty, Mark.empty, //
      Mark.o, Mark.o, Mark.empty, Mark.empty,
      Mark.empty, Mark.empty, Mark.empty, Mark.empty,
      Mark.empty, Mark.empty, Mark.empty, Mark.empty,
    ]);
    for (final difficulty in Difficulty.values) {
      final ai = GameAi(difficulty: difficulty, random: Random(3));
      expect(ai.chooseMove(board, aiMark, humanMark), const Position(1, 2));
    }
  });

  test('wins and blocks when it plays X', () {
    final rng = Random(9);
    final ai = GameAi(difficulty: Difficulty.hard, random: Random(9));
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

      final move = GameAi(
        difficulty: Difficulty.hard,
        random: Random(1),
      ).chooseMove(board, aiMark, humanMark);
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

      final move = GameAi(
        difficulty: Difficulty.hard,
        random: Random(1),
      ).chooseMove(board, aiMark, humanMark);
      expect(const [Position(3, 1), Position(3, 5)], contains(move));
      expect(winningCells(board.place(move, Mark.o), Mark.o), hasLength(2));
    });
  });
}
