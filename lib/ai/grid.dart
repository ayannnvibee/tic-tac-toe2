import 'dart:typed_data';

import '../domain/domain.dart';

/// A mutable scratch copy of a [Board] for the AI engines to search on.
///
/// Cells hold [empty], [ai] or [human] instead of X and O, so the engines do
/// not care which mark the computer plays.
class Grid {
  Grid._(this.size, this.winLength, this.cells);

  factory Grid.fromBoard(Board board, Mark aiMark, Mark humanMark) {
    if (aiMark == Mark.empty || humanMark == Mark.empty) {
      throw ArgumentError('Players cannot use the empty mark');
    }
    if (aiMark == humanMark) {
      throw ArgumentError('Both players cannot use $aiMark');
    }
    final cells = Int8List(board.cells.length);
    for (var i = 0; i < cells.length; i++) {
      final mark = board.cells[i];
      cells[i] = mark == Mark.empty ? empty : (mark == aiMark ? ai : human);
    }
    return Grid._(board.size, winLengthFor(board.size), cells);
  }

  static const int empty = 0;
  static const int ai = 1;
  static const int human = 2;

  /// Horizontal, vertical, diagonal, anti-diagonal.
  static const List<int> rowSteps = [0, 1, 1, 1];
  static const List<int> colSteps = [1, 0, 1, -1];

  final int size;
  final int winLength;
  final Int8List cells;

  static int opponentOf(int who) => who == ai ? human : ai;

  bool inBounds(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  bool get isFull => !cells.contains(empty);

  List<int> get emptyIndices => [
    for (var i = 0; i < cells.length; i++)
      if (cells[i] == empty) i,
  ];

  Position positionOf(int index) => Position(index ~/ size, index % size);

  /// Whether [who] has a winning run through [index], counting [index] itself
  /// as [who] whatever it currently holds.
  bool winsAt(int index, int who) {
    final row = index ~/ size;
    final col = index % size;
    for (var d = 0; d < 4; d++) {
      final run =
          1 + _count(row, col, d, 1, who) + _count(row, col, d, -1, who);
      if (run >= winLength) return true;
    }
    return false;
  }

  /// Consecutive [who] cells next to (row, col) going one way along direction
  /// [d]; [sign] is 1 for forwards and -1 for backwards.
  int runLength(int row, int col, int d, int sign, int who) =>
      _count(row, col, d, sign, who);

  int _count(int row, int col, int d, int sign, int who) {
    final dRow = rowSteps[d] * sign;
    final dCol = colSteps[d] * sign;
    var r = row + dRow;
    var c = col + dCol;
    var count = 0;
    while (r >= 0 &&
        r < size &&
        c >= 0 &&
        c < size &&
        cells[r * size + c] == who) {
      count++;
      r += dRow;
      c += dCol;
    }
    return count;
  }
}
