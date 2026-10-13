import 'dart:math';

import '../domain/domain.dart';
import 'ai_player.dart';
import 'difficulty_tuning.dart';
import 'heuristic_ai.dart';
import 'minimax_ai.dart';

/// The computer opponent: minimax on 3x3, the heuristic engine on anything
/// larger. Pass a seeded [random] for reproducible moves.
///
/// [tuning] replaces the table in difficulty_tuning.dart for every board
/// size; leave it null to use the table.
class GameAi implements AiPlayer {
  factory GameAi({
    Difficulty difficulty = defaultDifficulty,
    Random? random,
    DifficultyTuning? tuning,
    Duration timeBudget = aiTimeBudget,
  }) {
    // One generator shared by both engines keeps a seeded game reproducible.
    final shared = random ?? Random();
    return GameAi._(
      difficulty,
      MinimaxAi(difficulty: difficulty, random: shared, tuning: tuning),
      HeuristicAi(
        difficulty: difficulty,
        random: shared,
        tuning: tuning,
        timeBudget: timeBudget,
      ),
    );
  }

  GameAi._(this.difficulty, this._minimax, this._heuristic);

  final Difficulty difficulty;
  final MinimaxAi _minimax;
  final HeuristicAi _heuristic;

  @override
  Position chooseMove(Board board, Mark aiMark, Mark humanMark) =>
      board.size <= MinimaxAi.maxBoardSize
      ? _minimax.chooseMove(board, aiMark, humanMark)
      : _heuristic.chooseMove(board, aiMark, humanMark);
}
