import 'board.dart';
import 'player.dart';
import 'position.dart';
import 'rules.dart';
import 'win_checker.dart';

enum RoundStatus { inProgress, humanWon, computerWon, draw }

/// Why a move was not applied.
enum MoveRejection { occupied, outOfBounds, roundOver }

/// The outcome of [RoundState.applyMove].
sealed class MoveResult {
  const MoveResult();
}

final class MoveAccepted extends MoveResult {
  const MoveAccepted(this.state);

  /// The round after the move.
  final RoundState state;
}

final class MoveRejected extends MoveResult {
  const MoveRejected(this.reason);

  final MoveRejection reason;
}

/// One round on one board, from the first move to a win or a draw. Immutable.
class RoundState {
  const RoundState({
    required this.board,
    required this.currentTurn,
    required this.status,
    this.winningLine,
    this.lastMove,
  });

  /// A fresh round on an empty [size] x [size] board.
  factory RoundState.initial(int size) => RoundState(
    board: Board.empty(size),
    currentTurn: firstPlayerOfRound,
    status: RoundStatus.inProgress,
  );

  static const WinChecker _winChecker = WinChecker();

  final Board board;

  /// Whose move it is. Once the round is over this stays on the player who
  /// made the final move.
  final Player currentTurn;

  final RoundStatus status;

  /// The cells of the winning run, set only when someone has won.
  final List<Position>? winningLine;

  final Position? lastMove;

  bool get isOver => status != RoundStatus.inProgress;

  /// Places [currentTurn]'s mark at [position].
  ///
  /// The round must be in progress and the cell must be on the board and
  /// empty, otherwise the move is rejected and this state is unchanged.
  MoveResult applyMove(Position position) {
    if (isOver) return const MoveRejected(MoveRejection.roundOver);
    if (!board.contains(position)) {
      return const MoveRejected(MoveRejection.outOfBounds);
    }
    if (!board.isEmpty(position)) {
      return const MoveRejected(MoveRejection.occupied);
    }

    final nextBoard = board.place(position, currentTurn.mark);

    final line = _winChecker.winningLineFrom(nextBoard, position);
    if (line != null) {
      return MoveAccepted(
        RoundState(
          board: nextBoard,
          currentTurn: currentTurn,
          status: currentTurn == Player.human
              ? RoundStatus.humanWon
              : RoundStatus.computerWon,
          winningLine: line,
          lastMove: position,
        ),
      );
    }

    if (nextBoard.isFull) {
      return MoveAccepted(
        RoundState(
          board: nextBoard,
          currentTurn: currentTurn,
          status: RoundStatus.draw,
          lastMove: position,
        ),
      );
    }

    return MoveAccepted(
      RoundState(
        board: nextBoard,
        currentTurn: currentTurn.opponent,
        status: RoundStatus.inProgress,
        lastMove: position,
      ),
    );
  }
}
