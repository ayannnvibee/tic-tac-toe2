import 'dart:math';

import '../domain/domain.dart';
import 'ai_player.dart';
import 'difficulty_tuning.dart';
import 'grid.dart';

/// Exhaustive minimax with alpha-beta pruning. Only practical on 3x3.
///
/// * hard: perfect play, never loses.
/// * medium: perfect play, except that it sometimes blunders, as set in
///   difficulty_tuning.dart. A blunder plays a random one of the few best
///   moves, which is what lets the human win and progress.
/// * easy: takes a win, blocks a win, otherwise plays at random.
///
/// Every difficulty takes an immediate win when one exists.
class MinimaxAi implements AiPlayer {
  MinimaxAi({this.difficulty = defaultDifficulty, Random? random, this.tuning})
    : _random = random ?? Random();

  /// The largest board this engine will search.
  static const int maxBoardSize = 3;

  static const int _winScore = 10;

  final Difficulty difficulty;

  /// Overrides the table in difficulty_tuning.dart when set.
  final DifficultyTuning? tuning;

  final Random _random;

  @override
  Position chooseMove(Board board, Mark aiMark, Mark humanMark) {
    if (board.size > maxBoardSize) {
      throw ArgumentError.value(
        board.size,
        'board.size',
        'minimax only supports boards up to ${maxBoardSize}x$maxBoardSize',
      );
    }
    final grid = Grid.fromBoard(board, aiMark, humanMark);
    final empty = grid.emptyIndices;
    if (empty.isEmpty) throw StateError('The board is full');

    final wins = [
      for (final move in empty)
        if (grid.winsAt(move, Grid.ai)) move,
    ];
    if (wins.isNotEmpty) return _pick(grid, wins);

    // When the human threatens to win, only blocking moves are considered.
    // That costs nothing: every other move loses at once. It also means a
    // lost position (two threats) is still defended as far as possible.
    final blocks = [
      for (final move in empty)
        if (grid.winsAt(move, Grid.human)) move,
    ];
    final moves = blocks.isNotEmpty ? blocks : empty;

    if (difficulty == Difficulty.easy) return _pick(grid, moves);

    final active = tuning ?? tuningFor(difficulty, board.size);
    if (active.blunderChance > 0 &&
        _random.nextDouble() < active.blunderChance) {
      return _blunder(grid, empty, active.blunderPool);
    }

    final values = [for (final move in moves) _valueOf(grid, move)];
    final best = values.reduce(max);
    return _pick(grid, [
      for (var i = 0; i < moves.length; i++)
        if (values[i] == best) moves[i],
    ]);
  }

  Position _pick(Grid grid, List<int> moves) =>
      grid.positionOf(moves[_random.nextInt(moves.length)]);

  /// A random one of the [pool] best valued [moves]. Equal values are
  /// ordered at random, and a needed block is not forced.
  Position _blunder(Grid grid, List<int> moves, int pool) {
    final ranked = [
      for (final move in moves)
        (move: move, value: _valueOf(grid, move), tie: _random.nextDouble()),
    ];
    ranked.sort((a, b) {
      final byValue = b.value.compareTo(a.value);
      return byValue != 0 ? byValue : a.tie.compareTo(b.tie);
    });
    final top = min(pool, ranked.length);
    return grid.positionOf(ranked[_random.nextInt(top)].move);
  }

  /// The minimax value of the AI playing [move], which is known not to win
  /// immediately. Positive is good for the AI; sooner wins score higher.
  int _valueOf(Grid grid, int move) {
    grid.cells[move] = Grid.ai;
    final value = grid.isFull
        ? 0
        : _search(grid, Grid.human, 1, -_winScore, _winScore);
    grid.cells[move] = Grid.empty;
    return value;
  }

  int _search(Grid grid, int who, int depth, int alpha, int beta) {
    final maximizing = who == Grid.ai;
    final cells = grid.cells;
    var best = maximizing ? -_winScore : _winScore;

    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != Grid.empty) continue;

      cells[i] = who;
      final int score;
      if (grid.winsAt(i, who)) {
        score = maximizing ? _winScore - depth : depth - _winScore;
      } else if (grid.isFull) {
        score = 0;
      } else {
        score = _search(grid, Grid.opponentOf(who), depth + 1, alpha, beta);
      }
      cells[i] = Grid.empty;

      if (maximizing) {
        if (score > best) best = score;
        if (best > alpha) alpha = best;
      } else {
        if (score < best) best = score;
        if (best < beta) beta = best;
      }
      if (alpha >= beta) break;
    }
    return best;
  }
}
