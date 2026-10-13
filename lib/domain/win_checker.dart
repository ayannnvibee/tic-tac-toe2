import 'board.dart';
import 'player.dart';
import 'position.dart';
import 'rules.dart';

/// Detects winning runs of consecutive marks.
///
/// A run wins when it is at least the required length, in any of the four
/// directions, anywhere on the board. The returned line is the whole run, so
/// it can be longer than the required length.
class WinChecker {
  const WinChecker();

  /// Horizontal, vertical, diagonal, anti-diagonal as (row step, col step).
  static const List<(int, int)> _directions = [(0, 1), (1, 0), (1, 1), (1, -1)];

  /// The winning line that runs through [lastMove], or null if there is none.
  ///
  /// Only the four lines through [lastMove] are walked, so this is O(N) for a
  /// board of size N. [winLength] defaults to [winLengthFor] the board size.
  List<Position>? winningLineFrom(
    Board board,
    Position lastMove, {
    int? winLength,
  }) {
    final mark = board.cellAt(lastMove);
    if (mark == Mark.empty) return null;
    final needed = winLength ?? winLengthFor(board.size);

    for (final (dRow, dCol) in _directions) {
      var row = lastMove.row;
      var col = lastMove.col;
      while (_markAt(board, row - dRow, col - dCol) == mark) {
        row -= dRow;
        col -= dCol;
      }
      final line = _runFrom(board, row, col, dRow, dCol, mark);
      if (line.length >= needed) return List.unmodifiable(line);
    }
    return null;
  }

  /// Scans the whole board for a winning line. Slower than [winningLineFrom];
  /// meant for tests and for boards whose last move is unknown.
  List<Position>? findWinningLine(Board board, {int? winLength}) {
    final needed = winLength ?? winLengthFor(board.size);

    for (var row = 0; row < board.size; row++) {
      for (var col = 0; col < board.size; col++) {
        final mark = _markAt(board, row, col);
        if (mark == Mark.empty) continue;
        for (final (dRow, dCol) in _directions) {
          // Only measure a run from its first cell.
          if (_markAt(board, row - dRow, col - dCol) == mark) continue;
          final line = _runFrom(board, row, col, dRow, dCol, mark!);
          if (line.length >= needed) return List.unmodifiable(line);
        }
      }
    }
    return null;
  }

  List<Position> _runFrom(
    Board board,
    int row,
    int col,
    int dRow,
    int dCol,
    Mark mark,
  ) {
    final line = <Position>[];
    while (_markAt(board, row, col) == mark) {
      line.add(Position(row, col));
      row += dRow;
      col += dCol;
    }
    return line;
  }

  /// The mark at (row, col), or null when that is off the board.
  Mark? _markAt(Board board, int row, int col) {
    if (row < 0 || row >= board.size || col < 0 || col >= board.size) {
      return null;
    }
    return board.cells[row * board.size + col];
  }
}
