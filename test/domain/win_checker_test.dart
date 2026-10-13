import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

const _directions = <String, (int, int)>{
  'horizontal': (0, 1),
  'vertical': (1, 0),
  'diagonal': (1, 1),
  'anti-diagonal': (1, -1),
};

bool _fits(int size, Position start, int dRow, int dCol, int length) {
  final endRow = start.row + dRow * (length - 1);
  final endCol = start.col + dCol * (length - 1);
  return endRow >= 0 && endRow < size && endCol >= 0 && endCol < size;
}

void main() {
  const checker = WinChecker();

  group('wins at every position', () {
    for (final size in [3, 4, 5, 6, 7]) {
      final length = winLengthFor(size);
      _directions.forEach((name, step) {
        final (dRow, dCol) = step;
        test('${size}x$size $name run of $length', () {
          var checked = 0;
          for (var row = 0; row < size; row++) {
            for (var col = 0; col < size; col++) {
              final start = Position(row, col);
              if (!_fits(size, start, dRow, dCol, length)) continue;
              final expected = line(start, dRow, dCol, length);
              final board = boardWith(size, expected);

              expect(checker.findWinningLine(board), expected);
              for (final lastMove in expected) {
                expect(
                  checker.winningLineFrom(board, lastMove),
                  expected,
                  reason: 'last move $lastMove on\n$board',
                );
              }
              checked++;
            }
          }
          expect(checked, greaterThan(0));
        });
      });
    }
  });

  group('runs that do not touch an edge', () {
    _directions.forEach((name, step) {
      final (dRow, dCol) = step;
      test('7x7 $name run of 5 in the middle', () {
        final start = dCol < 0 ? const Position(1, 5) : const Position(1, 1);
        final expected = line(start, dRow, dCol, 5);
        final board = boardWith(7, expected, Mark.o);

        expect(checker.findWinningLine(board), expected);
        expect(checker.winningLineFrom(board, expected[2]), expected);
      });
    });
  });

  group('6x6', () {
    test('a run of 5 wins', () {
      final board = boardFrom([
        '......',
        '......',
        '.XXXXX',
        '......',
        '......',
        '......',
      ]);
      final expected = line(const Position(2, 1), 0, 1, 5);
      expect(checker.findWinningLine(board), expected);
      expect(checker.winningLineFrom(board, const Position(2, 3)), expected);
    });

    _directions.forEach((name, step) {
      final (dRow, dCol) = step;
      test('a $name run of 4 does not win', () {
        final start = dCol < 0 ? const Position(1, 4) : const Position(1, 1);
        final cells = line(start, dRow, dCol, 4);
        final board = boardWith(6, cells);

        expect(checker.findWinningLine(board), isNull);
        for (final lastMove in cells) {
          expect(checker.winningLineFrom(board, lastMove), isNull);
        }
      });
    });
  });

  test('a run longer than required returns the whole run', () {
    final expected = line(const Position(3, 0), 0, 1, 6);
    final board = boardWith(7, expected);

    expect(checker.findWinningLine(board), expected);
    expect(checker.winningLineFrom(board, const Position(3, 2)), expected);
  });

  test('the win length can be overridden', () {
    final board = boardFrom(['XXX..', '.....', '.....', '.....', '.....']);
    expect(checker.findWinningLine(board), isNull);
    expect(
      checker.findWinningLine(board, winLength: 3),
      line(const Position(0, 0), 0, 1, 3),
    );
    expect(
      checker.winningLineFrom(board, const Position(0, 1), winLength: 3),
      line(const Position(0, 0), 0, 1, 3),
    );
  });

  group('no false positives', () {
    void expectNoWin(Board board) {
      expect(checker.findWinningLine(board), isNull, reason: '\n$board');
      for (var row = 0; row < board.size; row++) {
        for (var col = 0; col < board.size; col++) {
          expect(
            checker.winningLineFrom(board, Position(row, col)),
            isNull,
            reason: 'last move ($row, $col) on\n$board',
          );
        }
      }
    }

    test('empty board and an empty last move', () {
      expectNoWin(Board.empty(3));
      expectNoWin(Board.empty(7));
    });

    test('run broken by an empty cell', () {
      expectNoWin(boardFrom(['XX.XX', '.....', '.....', '.....', '.....']));
      expectNoWin(boardFrom(['X..', '...', '..X']));
    });

    test('run broken by the opponent', () {
      expectNoWin(
        boardFrom([
          'XXOXXX.',
          '.......',
          '.......',
          '.......',
          '.......',
          '.......',
          '.......',
        ]),
      );
      expectNoWin(boardFrom(['X...', '.X..', '..O.', '...X']));
    });

    test('mixed marks in one line', () {
      expectNoWin(boardFrom(['XOX', '...', '...']));
    });

    test('horizontal run that wraps onto the next row', () {
      // Flat indices 1, 2, 3 are consecutive but span two rows.
      expectNoWin(boardFrom(['.XX', 'X..', '...']));
      expectNoWin(boardFrom(['..XX', 'XX..', '....', '....']));
      expectNoWin(boardFrom(['...XX', 'XXX..', '.....', '.....', '.....']));
    });

    test('diagonal run that wraps around the right edge', () {
      // Flat indices 2, 9, 16, 23, 30 step by size + 1 on a 6x6 board.
      expectNoWin(
        boardFrom(['..X...', '...X..', '....X.', '.....X', '......', 'X.....']),
      );
    });

    test('anti-diagonal run that wraps around the left edge', () {
      // Flat indices 0, 3, 6, 9 step by size - 1 on a 4x4 board.
      expectNoWin(boardFrom(['X..X', '..X.', '.X..', '....']));
      // Flat indices 1, 3, 5 step by size - 1 on a 3x3 board.
      expectNoWin(boardFrom(['.X.', 'X.X', '...']));
    });

    test('a full drawn board', () {
      expectNoWin(boardFrom(['XOX', 'OOX', 'XXO']));
    });
  });
}
