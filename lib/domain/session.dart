import 'round_state.dart';
import 'rules.dart';

/// Everything that lasts across rounds: the level and both win counters, plus
/// the round being played. Immutable, and never persisted.
class Session {
  const Session({
    required this.boardSize,
    required this.humanWins,
    required this.computerWins,
    required this.round,
  });

  /// A 3x3 board, 0/0, human to move.
  factory Session.initial() => Session(
    boardSize: initialBoardSize,
    humanWins: 0,
    computerWins: 0,
    round: RoundState.initial(initialBoardSize),
  );

  final int boardSize;
  final int humanWins;
  final int computerWins;
  final RoundState round;

  /// This session with its current round replaced, e.g. after a move.
  Session withRound(RoundState round) {
    if (round.board.size != boardSize) {
      throw ArgumentError.value(
        round.board.size,
        'round.board.size',
        'must match the session board size $boardSize',
      );
    }
    return Session(
      boardSize: boardSize,
      humanWins: humanWins,
      computerWins: computerWins,
      round: round,
    );
  }

  /// The session that follows a round which ended with [result].
  ///
  /// A human win grows the board by one, a computer win replays the same
  /// size, and a draw resets everything. Throws an [ArgumentError] for
  /// [RoundStatus.inProgress], since no round has ended.
  Session nextRoundAfter(RoundStatus result) {
    switch (result) {
      case RoundStatus.humanWon:
        final nextSize = boardSize + 1;
        return Session(
          boardSize: nextSize,
          humanWins: humanWins + 1,
          computerWins: computerWins,
          round: RoundState.initial(nextSize),
        );
      case RoundStatus.computerWon:
        return Session(
          boardSize: boardSize,
          humanWins: humanWins,
          computerWins: computerWins + 1,
          round: RoundState.initial(boardSize),
        );
      case RoundStatus.draw:
        return Session.initial();
      case RoundStatus.inProgress:
        throw ArgumentError.value(
          result,
          'result',
          'the round has not finished',
        );
    }
  }

  /// A full reset, the same as after a draw.
  Session newGame() => Session.initial();
}
