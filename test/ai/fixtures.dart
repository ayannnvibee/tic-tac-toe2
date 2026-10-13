import 'dart:math';

import 'package:tic_tac_toe_infinity/ai/ai.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

const WinChecker winChecker = WinChecker();

const Mark aiMark = Mark.o;
const Mark humanMark = Mark.x;

/// Blunders on every move, for tests that need the worst case.
const DifficultyTuning alwaysBlunder = DifficultyTuning(
  blunderChance: 1,
  blunderPool: 3,
);

/// The empty cells where [mark] would win by playing there.
Set<Position> winningCells(Board board, Mark mark) => {
  for (final cell in board.emptyCells)
    if (winChecker.winningLineFrom(board.place(cell, mark), cell) != null) cell,
};

/// Places [mark] at [cell] unless that would complete a winning run.
Board placeUnlessWinning(Board board, Position cell, Mark mark) {
  final next = board.place(cell, mark);
  return winChecker.winningLineFrom(next, cell) == null ? next : board;
}

/// A board with up to [marks] alternating random marks and no winner.
Board randomBoard(Random rng, int size, int marks) {
  var board = Board.empty(size);
  final cells = board.emptyCells..shuffle(rng);
  var mark = Mark.x;
  for (final cell in cells.take(min(marks, size * size - 1))) {
    board = placeUnlessWinning(board, cell, mark);
    mark = mark == Mark.x ? Mark.o : Mark.x;
  }
  return board;
}

/// A board where [attacker] is one move from winning: winLength-1 marks on a
/// random line with a single gap, plus a little random noise and no winner.
Board boardWithThreat(Random rng, int size, Mark attacker) {
  final length = winLengthFor(size);
  const steps = [(0, 1), (1, 0), (1, 1), (1, -1)];

  while (true) {
    final (dRow, dCol) = steps[rng.nextInt(steps.length)];
    final row = rng.nextInt(size);
    final col = rng.nextInt(size);
    final endRow = row + dRow * (length - 1);
    final endCol = col + dCol * (length - 1);
    if (endRow >= size || endCol < 0 || endCol >= size) continue;

    final gap = rng.nextInt(length);
    final lineCells = [
      for (var i = 0; i < length; i++) Position(row + dRow * i, col + dCol * i),
    ];
    var board = Board.empty(size);
    for (var i = 0; i < length; i++) {
      if (i != gap) board = board.place(lineCells[i], attacker);
    }

    final others = board.emptyCells
      ..remove(lineCells[gap])
      ..shuffle(rng);
    var mark = attacker == Mark.x ? Mark.o : Mark.x;
    for (final cell in others.take(rng.nextInt(size + 1))) {
      board = placeUnlessWinning(board, cell, mark);
      mark = mark == Mark.x ? Mark.o : Mark.x;
    }
    return board;
  }
}

/// Plays a whole round: a seeded random human (X, first) against [ai] (O).
/// Returns every move in order.
List<Position> playRound(AiPlayer ai, int size, int humanSeed) {
  final humanRng = Random(humanSeed);
  final moves = <Position>[];
  var round = RoundState.initial(size);

  while (!round.isOver) {
    final Position move;
    if (round.currentTurn == Player.human) {
      final empty = round.board.emptyCells;
      move = empty[humanRng.nextInt(empty.length)];
    } else {
      move = ai.chooseMove(round.board, aiMark, humanMark);
    }
    moves.add(move);
    round = (round.applyMove(move) as MoveAccepted).state;
  }
  return moves;
}
