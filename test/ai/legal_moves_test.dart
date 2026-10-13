import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

void main() {
  void expectLegal(Board board, Position move) {
    expect(board.contains(move), isTrue, reason: '$move is off\n$board');
    expect(board.isEmpty(move), isTrue, reason: '$move is taken on\n$board');
  }

  group('never returns an occupied or out-of-range cell', () {
    for (var size = 3; size <= 10; size++) {
      for (final difficulty in Difficulty.values) {
        test('${size}x$size ${difficulty.name}', () {
          final rng = Random(size * 31 + difficulty.index);
          final ai = GameAi(difficulty: difficulty, random: Random(size));

          for (var i = 0; i < 60; i++) {
            final board = randomBoard(rng, size, rng.nextInt(size * size));
            if (board.isFull) continue;
            expectLegal(board, ai.chooseMove(board, Mark.o, Mark.x));
            expectLegal(board, ai.chooseMove(board, Mark.x, Mark.o));
          }
        });
      }
    }
  });

  test('plays the centre of an empty large board', () {
    final ai = GameAi(random: Random(1));
    expect(
      ai.chooseMove(Board.empty(7), aiMark, humanMark),
      const Position(3, 3),
    );
    expectLegal(
      Board.empty(10),
      ai.chooseMove(Board.empty(10), aiMark, humanMark),
    );
    expectLegal(
      Board.empty(3),
      ai.chooseMove(Board.empty(3), aiMark, humanMark),
    );
  });

  test('plays the only empty cell', () {
    for (final size in [3, 4, 6]) {
      var board = Board.empty(size);
      final cells = board.emptyCells;
      const last = Position(1, 2);
      var mark = Mark.x;
      for (final cell in cells) {
        if (cell == last) continue;
        // Winners do not matter here, only that one cell is left.
        board = board.place(cell, mark);
        mark = mark == Mark.x ? Mark.o : Mark.x;
      }
      for (final difficulty in Difficulty.values) {
        final ai = GameAi(difficulty: difficulty, random: Random(2));
        expect(ai.chooseMove(board, aiMark, humanMark), last);
      }
    }
  });

  test('a full board is an error', () {
    final full = Board.fromCells(3, List.filled(9, Mark.x));
    expect(
      () => GameAi().chooseMove(full, aiMark, humanMark),
      throwsStateError,
    );
    final fullLarge = Board.fromCells(5, List.filled(25, Mark.x));
    expect(
      () => GameAi().chooseMove(fullLarge, aiMark, humanMark),
      throwsStateError,
    );
  });

  test('marks must be two different non-empty marks', () {
    final board = Board.empty(5);
    expect(
      () => GameAi().chooseMove(board, Mark.o, Mark.o),
      throwsArgumentError,
    );
    expect(
      () => GameAi().chooseMove(board, Mark.empty, Mark.x),
      throwsArgumentError,
    );
  });

  test('default difficulty is medium', () {
    expect(defaultDifficulty, Difficulty.medium);
    expect(GameAi().difficulty, Difficulty.medium);
  });

  test('lib/ai and lib/domain do not import Flutter', () {
    for (final folder in ['lib/ai', 'lib/domain']) {
      final files = Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          file.readAsStringSync(),
          isNot(contains('package:flutter')),
          reason: file.path,
        );
      }
    }
  });
}
