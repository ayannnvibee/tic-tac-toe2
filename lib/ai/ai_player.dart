import '../domain/domain.dart';

/// How strong the computer plays. Only [medium] is tuned for launch.
enum Difficulty { easy, medium, hard }

const Difficulty defaultDifficulty = Difficulty.medium;

/// Something that can pick the computer's next move.
abstract class AiPlayer {
  /// The empty cell [aiMark] should play on [board].
  ///
  /// Throws a [StateError] if the board has no empty cell.
  Position chooseMove(Board board, Mark aiMark, Mark humanMark);
}
