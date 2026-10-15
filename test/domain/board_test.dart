import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

void main() {
  group('Position', () {
    test('has value equality', () {
      expect(const Position(1, 2), const Position(1, 2));
      expect(const Position(1, 2).hashCode, const Position(1, 2).hashCode);
      expect(const Position(1, 2), isNot(const Position(2, 1)));
    });
  });

  group('winLengthFor', () {
    test('is 3 up to 4x4, 4 on 5x5 and 5 from 6x6', () {
      expect(winLengthFor(3), 3);
      expect(winLengthFor(4), 3);
      expect(winLengthFor(5), 4);
      expect(winLengthFor(6), 5);
      expect(winLengthFor(12), 5);
    });
  });

  group('Player', () {
    test('human is X and computer is O', () {
      expect(Player.human.mark, Mark.x);
      expect(Player.computer.mark, Mark.o);
    });
  });

  group('Board', () {
    test('empty board has size*size empty cells', () {
      final board = Board.empty(4);
      expect(board.size, 4);
      expect(board.cells, hasLength(16));
      expect(board.emptyCells, hasLength(16));
      expect(board.isFull, isFalse);
      expect(board.isEmpty(const Position(3, 3)), isTrue);
    });

    test('place returns a new board and leaves the original unchanged', () {
      final before = Board.empty(3);
      final after = before.place(const Position(1, 2), Mark.x);

      expect(before.cellAt(const Position(1, 2)), Mark.empty);
      expect(after.cellAt(const Position(1, 2)), Mark.x);
      expect(after.isEmpty(const Position(1, 2)), isFalse);
      expect(after.emptyCells, hasLength(8));
      expect(after.emptyCells, isNot(contains(const Position(1, 2))));
    });

    test('cells are stored row by row in a flat list', () {
      final board = Board.empty(3).place(const Position(1, 2), Mark.o);
      expect(board.cells[1 * 3 + 2], Mark.o);
    });

    test('cells cannot be modified from outside', () {
      final board = Board.empty(3);
      expect(() => board.cells[0] = Mark.x, throwsUnsupportedError);
    });

    test('place fails on an occupied cell', () {
      final board = Board.empty(3).place(const Position(0, 0), Mark.x);
      expect(() => board.place(const Position(0, 0), Mark.o), throwsStateError);
    });

    test('place and cellAt fail out of range', () {
      final board = Board.empty(3);
      for (final pos in const [
        Position(-1, 0),
        Position(0, -1),
        Position(3, 0),
        Position(0, 3),
      ]) {
        expect(() => board.place(pos, Mark.x), throwsRangeError);
        expect(() => board.cellAt(pos), throwsRangeError);
      }
    });

    test('place rejects the empty mark', () {
      expect(
        () => Board.empty(3).place(const Position(0, 0), Mark.empty),
        throwsArgumentError,
      );
    });

    test('isFull once every cell is marked', () {
      final board = boardFrom(['XOX', 'OOX', 'XXO']);
      expect(board.isFull, isTrue);
      expect(board.emptyCells, isEmpty);
    });

    test('boards with the same cells are equal', () {
      final a = Board.empty(3).place(const Position(1, 1), Mark.x);
      final b = boardFrom(['...', '.X.', '...']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(Board.empty(3)));
    });
  });
}
