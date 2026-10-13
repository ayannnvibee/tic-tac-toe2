import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

void main() {
  MoveRejection rejectionOf(MoveResult result) {
    expect(result, isA<MoveRejected>());
    return (result as MoveRejected).reason;
  }

  group('RoundState.initial', () {
    test('is an empty board in progress with the human to move', () {
      final round = RoundState.initial(4);
      expect(round.board, Board.empty(4));
      expect(round.status, RoundStatus.inProgress);
      expect(round.currentTurn, Player.human);
      expect(firstPlayerOfRound, Player.human);
      expect(round.winningLine, isNull);
      expect(round.lastMove, isNull);
      expect(round.isOver, isFalse);
    });
  });

  group('applyMove', () {
    test('a legal move places the mark and records the last move', () {
      final start = RoundState.initial(3);
      final result = start.applyMove(const Position(1, 1));

      expect(result, isA<MoveAccepted>());
      final next = (result as MoveAccepted).state;
      expect(next.board.cellAt(const Position(1, 1)), Mark.x);
      expect(next.lastMove, const Position(1, 1));
      expect(next.status, RoundStatus.inProgress);
      expect(next.winningLine, isNull);
      // The state the move was applied to is untouched.
      expect(start.board, Board.empty(3));
      expect(start.currentTurn, Player.human);
    });

    test('turns alternate and each player places their own mark', () {
      var round = RoundState.initial(3);
      expect(round.currentTurn, Player.human);

      round = play(round, const [Position(0, 0)]);
      expect(round.currentTurn, Player.computer);
      expect(round.board.cellAt(const Position(0, 0)), Mark.x);

      round = play(round, const [Position(1, 1)]);
      expect(round.currentTurn, Player.human);
      expect(round.board.cellAt(const Position(1, 1)), Mark.o);

      round = play(round, const [Position(2, 2)]);
      expect(round.currentTurn, Player.computer);
      expect(round.board.cellAt(const Position(2, 2)), Mark.x);
    });

    test('an occupied cell is rejected and the turn does not change', () {
      final round = play(RoundState.initial(3), const [Position(0, 0)]);

      expect(
        rejectionOf(round.applyMove(const Position(0, 0))),
        MoveRejection.occupied,
      );
      expect(round.currentTurn, Player.computer);
      expect(round.board.cellAt(const Position(0, 0)), Mark.x);
    });

    test('out of bounds is rejected', () {
      final round = RoundState.initial(3);
      for (final pos in const [
        Position(-1, 0),
        Position(0, -1),
        Position(3, 0),
        Position(0, 3),
        Position(9, 9),
      ]) {
        expect(
          rejectionOf(round.applyMove(pos)),
          MoveRejection.outOfBounds,
          reason: '$pos',
        );
      }
    });

    test('a move after the round is over is rejected', () {
      final won = play(RoundState.initial(3), const [
        Position(0, 0),
        Position(1, 0),
        Position(0, 1),
        Position(1, 1),
        Position(0, 2),
      ]);
      expect(won.status, RoundStatus.humanWon);

      // An empty cell, an occupied cell and an off-board cell all report
      // that the round is over.
      for (final pos in const [
        Position(2, 2),
        Position(0, 0),
        Position(5, 5),
      ]) {
        expect(rejectionOf(won.applyMove(pos)), MoveRejection.roundOver);
      }
    });
  });

  group('round result', () {
    test('human win sets the status and the winning line', () {
      final round = play(RoundState.initial(3), const [
        Position(0, 0),
        Position(1, 0),
        Position(0, 1),
        Position(1, 1),
        Position(0, 2),
      ]);

      expect(round.status, RoundStatus.humanWon);
      expect(round.isOver, isTrue);
      expect(round.winningLine, const [
        Position(0, 0),
        Position(0, 1),
        Position(0, 2),
      ]);
      expect(round.lastMove, const Position(0, 2));
    });

    test('computer win sets the status and the winning line', () {
      final round = play(RoundState.initial(3), const [
        Position(0, 0),
        Position(1, 0),
        Position(0, 1),
        Position(1, 1),
        Position(2, 2),
        Position(1, 2),
      ]);

      expect(round.status, RoundStatus.computerWon);
      expect(round.winningLine, const [
        Position(1, 0),
        Position(1, 1),
        Position(1, 2),
      ]);
    });

    test('a full board with no winner is a draw', () {
      final round = play(RoundState.initial(3), const [
        Position(0, 0),
        Position(1, 1),
        Position(0, 2),
        Position(0, 1),
        Position(2, 1),
        Position(1, 0),
        Position(1, 2),
        Position(2, 2),
        Position(2, 0),
      ]);

      expect(round.board, boardFrom(['XOX', 'OOX', 'XXO']));
      expect(round.board.isFull, isTrue);
      expect(round.status, RoundStatus.draw);
      expect(round.winningLine, isNull);
      expect(round.isOver, isTrue);
    });

    test('a win on the last empty cell is a win, not a draw', () {
      final round = play(RoundState.initial(3), const [
        Position(0, 0),
        Position(0, 1),
        Position(0, 2),
        Position(1, 1),
        Position(1, 0),
        Position(1, 2),
        Position(2, 1),
        Position(2, 2),
        Position(2, 0),
      ]);

      expect(round.board.isFull, isTrue);
      expect(round.status, RoundStatus.humanWon);
      expect(round.winningLine, const [
        Position(0, 0),
        Position(1, 0),
        Position(2, 0),
      ]);
    });

    test('three in a row does not end a 4x4 round', () {
      final round = play(RoundState.initial(4), const [
        Position(0, 0),
        Position(3, 0),
        Position(0, 1),
        Position(3, 1),
        Position(0, 2),
      ]);
      expect(round.status, RoundStatus.inProgress);

      final won = play(round, const [Position(3, 2), Position(0, 3)]);
      expect(won.status, RoundStatus.humanWon);
      expect(won.winningLine, hasLength(4));
    });
  });
}
