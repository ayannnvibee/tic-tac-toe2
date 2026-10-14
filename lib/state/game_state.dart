import '../ai/ai.dart';
import '../domain/domain.dart';

/// Everything the UI needs to draw the game. Immutable, and never persisted:
/// every app launch starts from [GameState.initial].
class GameState {
  const GameState({
    required this.session,
    this.isAiThinking = false,
    this.pendingResult,
    this.roundId = 0,
    this.difficulty = defaultDifficulty,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  /// A 3x3 board, 0/0, human to move.
  factory GameState.initial() => GameState(session: Session.initial());

  final Session session;

  /// True from the human's move until the computer's reply is on the board.
  final bool isAiThinking;

  /// How the current round ended, or null while it is still being played.
  /// The finished board stays in [session] until the next round is started.
  final RoundStatus? pendingResult;

  /// Counts the rounds started in this session. It changes whenever a fresh
  /// board replaces the one in play, which is what the board transition and
  /// the round end sequence key on.
  final int roundId;

  final Difficulty difficulty;
  final bool soundEnabled;
  final bool hapticsEnabled;

  static const Object _unchanged = Object();

  GameState copyWith({
    Session? session,
    bool? isAiThinking,
    Object? pendingResult = _unchanged,
    int? roundId,
    Difficulty? difficulty,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) => GameState(
    session: session ?? this.session,
    isAiThinking: isAiThinking ?? this.isAiThinking,
    pendingResult: identical(pendingResult, _unchanged)
        ? this.pendingResult
        : pendingResult as RoundStatus?,
    roundId: roundId ?? this.roundId,
    difficulty: difficulty ?? this.difficulty,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
  );
}
