import 'dart:isolate';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

void main() {
  group('same seed gives the same moves', () {
    for (final size in [3, 4, 6, 9]) {
      for (final difficulty in Difficulty.values) {
        test('${size}x$size ${difficulty.name}', () {
          for (var seed = 0; seed < 5; seed++) {
            List<Position> run() => playRound(
              GameAi(
                difficulty: difficulty,
                random: Random(seed),
                blunderChance: 0.5,
              ),
              size,
              seed + 1000,
            );

            final first = run();
            expect(first, isNotEmpty);
            expect(run(), first);
          }
        });
      }
    }

    test('different seeds can give different games', () {
      final games = {
        for (var seed = 0; seed < 20; seed++)
          playRound(
            GameAi(random: Random(seed), blunderChance: 0.5),
            3,
            7,
          ).join(','),
      };
      expect(games.length, greaterThan(1));
    });
  });

  group('computeAiMove', () {
    final board = Board.empty(6)
        .place(const Position(2, 2), Mark.x)
        .place(const Position(3, 3), Mark.o)
        .place(const Position(2, 3), Mark.x);

    test('request carries the board as plain ints', () {
      final request = AiRequest.fromBoard(board, seed: 4);
      expect(request.size, 6);
      expect(request.cells, hasLength(36));
      expect(request.cells[2 * 6 + 2], Mark.x.index);
      expect(request.cells[3 * 6 + 3], Mark.o.index);
      expect(request.difficulty, Difficulty.medium);
      expect(request.toBoard(), board);
    });

    test('returns a legal move and repeats for the same request', () {
      for (final difficulty in Difficulty.values) {
        final request = AiRequest.fromBoard(
          board,
          seed: 11,
          difficulty: difficulty,
        );
        final move = computeAiMove(request);
        expect(board.isEmpty(move), isTrue);
        expect(computeAiMove(request), move);
      }
    });

    test('matches GameAi with the same seed', () {
      final request = AiRequest.fromBoard(board, seed: 21);
      expect(
        computeAiMove(request),
        GameAi(random: Random(21)).chooseMove(board, Mark.o, Mark.x),
      );
    });

    test('takes the win on 3x3 for either mark', () {
      final almost = Board.empty(3)
          .place(const Position(0, 0), Mark.x)
          .place(const Position(1, 0), Mark.o)
          .place(const Position(0, 1), Mark.x)
          .place(const Position(1, 1), Mark.o);
      expect(
        computeAiMove(AiRequest.fromBoard(almost, seed: 1)),
        const Position(1, 2),
      );
      expect(
        computeAiMove(AiRequest.fromBoard(almost, seed: 1, aiMark: Mark.x)),
        const Position(0, 2),
      );
    });

    test('runs in another isolate', () async {
      final request = AiRequest.fromBoard(board, seed: 33);
      final move = await Isolate.run(() => computeAiMove(request));
      expect(move, computeAiMove(request));
    });
  });
}
