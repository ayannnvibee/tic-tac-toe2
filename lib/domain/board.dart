import 'player.dart';
import 'position.dart';

/// An immutable square board of [size] x [size] cells.
///
/// Cells are stored row by row in a flat list: the cell at (row, col) lives at
/// index `row * size + col`.
class Board {
  Board._(this.size, this.cells);

  /// A board of [size] x [size] with every cell empty.
  factory Board.empty(int size) {
    if (size < 1) {
      throw ArgumentError.value(size, 'size', 'must be at least 1');
    }
    return Board._(
      size,
      List.unmodifiable(List.filled(size * size, Mark.empty)),
    );
  }

  /// A board built from a flat, row by row list of [cells].
  factory Board.fromCells(int size, List<Mark> cells) {
    if (size < 1) {
      throw ArgumentError.value(size, 'size', 'must be at least 1');
    }
    if (cells.length != size * size) {
      throw ArgumentError.value(
        cells.length,
        'cells.length',
        'must be ${size * size} for a board of size $size',
      );
    }
    return Board._(size, List.unmodifiable(cells));
  }

  final int size;

  /// The cells row by row. Unmodifiable.
  final List<Mark> cells;

  bool contains(Position pos) =>
      pos.row >= 0 && pos.row < size && pos.col >= 0 && pos.col < size;

  /// The mark at [pos]. Throws a [RangeError] if [pos] is off the board.
  Mark cellAt(Position pos) {
    _checkInRange(pos);
    return cells[pos.row * size + pos.col];
  }

  bool isEmpty(Position pos) => cellAt(pos) == Mark.empty;

  /// Returns a new board with [mark] at [pos]; this board is left unchanged.
  ///
  /// Throws a [RangeError] if [pos] is off the board, a [StateError] if the
  /// cell is already marked, and an [ArgumentError] if [mark] is [Mark.empty].
  Board place(Position pos, Mark mark) {
    if (mark == Mark.empty) {
      throw ArgumentError.value(mark, 'mark', 'cannot place an empty mark');
    }
    _checkInRange(pos);
    final index = pos.row * size + pos.col;
    if (cells[index] != Mark.empty) {
      throw StateError('Cell $pos is already occupied');
    }
    final next = List<Mark>.of(cells);
    next[index] = mark;
    return Board._(size, List.unmodifiable(next));
  }

  List<Position> get emptyCells => [
    for (var i = 0; i < cells.length; i++)
      if (cells[i] == Mark.empty) Position(i ~/ size, i % size),
  ];

  bool get isFull => !cells.contains(Mark.empty);

  void _checkInRange(Position pos) {
    if (!contains(pos)) {
      throw RangeError('$pos is outside a ${size}x$size board');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Board || other.size != size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        buffer.write(switch (cells[row * size + col]) {
          Mark.empty => '.',
          Mark.x => 'X',
          Mark.o => 'O',
        });
      }
      if (row < size - 1) buffer.write('\n');
    }
    return buffer.toString();
  }
}
