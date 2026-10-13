import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

/// Builds a board from rows of 'X', 'O' and '.' characters.
Board boardFrom(List<String> rows) {
  final size = rows.length;
  final cells = <Mark>[];
  for (final row in rows) {
    expect(row.length, size, reason: 'row "$row" must have $size cells');
    for (final char in row.split('')) {
      cells.add(switch (char) {
        'X' => Mark.x,
        'O' => Mark.o,
        '.' => Mark.empty,
        _ => throw ArgumentError('Unknown cell "$char"'),
      });
    }
  }
  return Board.fromCells(size, cells);
}

/// Applies [moves] in order, failing the test if any of them is rejected.
RoundState play(RoundState start, List<Position> moves) {
  var state = start;
  for (final move in moves) {
    final result = state.applyMove(move);
    expect(result, isA<MoveAccepted>(), reason: 'move $move was rejected');
    state = (result as MoveAccepted).state;
  }
  return state;
}

/// [length] positions starting at [start], stepping by ([dRow], [dCol]).
List<Position> line(Position start, int dRow, int dCol, int length) => [
  for (var i = 0; i < length; i++)
    Position(start.row + dRow * i, start.col + dCol * i),
];

/// An otherwise empty board of [size] with [mark] on every cell of [cells].
Board boardWith(int size, List<Position> cells, [Mark mark = Mark.x]) {
  var board = Board.empty(size);
  for (final cell in cells) {
    board = board.place(cell, mark);
  }
  return board;
}
