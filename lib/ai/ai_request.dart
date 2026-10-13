import 'dart:math';

import '../domain/domain.dart';
import 'ai_player.dart';
import 'game_ai.dart';

/// Everything [computeAiMove] needs, as plain values that can be sent to
/// another isolate.
class AiRequest {
  const AiRequest({
    required this.cells,
    required this.size,
    required this.seed,
    this.difficulty = defaultDifficulty,
    this.aiMark = Mark.o,
  });

  factory AiRequest.fromBoard(
    Board board, {
    required int seed,
    Difficulty difficulty = defaultDifficulty,
    Mark aiMark = Mark.o,
  }) => AiRequest(
    cells: [for (final mark in board.cells) mark.index],
    size: board.size,
    seed: seed,
    difficulty: difficulty,
    aiMark: aiMark,
  );

  /// The board row by row, each cell as its [Mark] index:
  /// 0 empty, 1 X, 2 O.
  final List<int> cells;

  final int size;

  final Difficulty difficulty;

  /// Seeds the engine's random choices. Use a new seed for every move: the
  /// same seed on the same board always gives the same move.
  final int seed;

  /// The mark the computer plays; the human plays the other one.
  final Mark aiMark;

  Board toBoard() =>
      Board.fromCells(size, [for (final cell in cells) Mark.values[cell]]);
}

/// Picks the computer's move for [request]. A top-level function so it can be
/// run off the UI thread with `Isolate.run(() => computeAiMove(request))`.
Position computeAiMove(AiRequest request) {
  final humanMark = request.aiMark == Mark.o ? Mark.x : Mark.o;
  return GameAi(
    difficulty: request.difficulty,
    random: Random(request.seed),
  ).chooseMove(request.toBoard(), request.aiMark, humanMark);
}
