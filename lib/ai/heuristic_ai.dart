import 'dart:math';

import '../domain/domain.dart';
import 'ai_player.dart';
import 'difficulty_tuning.dart';
import 'grid.dart';

/// Rule and score based engine for 4x4 boards and larger.
///
/// In order:
///  1. Win now if possible.
///  2. Block the human's immediate win.
///  3. Threats: create a double winning threat, block the cell where the
///     human would create one (an open run of winLength-2 and similar), then
///     create an open run of winLength-2.
///  4. Otherwise score every candidate cell with a line-window heuristic.
///  5. Candidates are the empty cells within [candidateRadius] of a mark.
///  6. A depth-2 look at the best [searchWidth] candidates, inside
///     [timeBudget]; if the budget runs out the best heuristic move is played.
///
/// Easy stops after step 2 and plays a random candidate. Hard runs every
/// step. Medium does too, except that it sometimes blunders, as set in
/// difficulty_tuning.dart: after step 1 it plays a random one of the few best
/// scored cells and skips the block and threat rules.
class HeuristicAi implements AiPlayer {
  HeuristicAi({
    this.difficulty = defaultDifficulty,
    Random? random,
    this.tuning,
    this.timeBudget = aiTimeBudget,
    this.searchWidth = aiSearchWidth,
  }) : _random = random ?? Random();

  static const int candidateRadius = aiCandidateRadius;

  /// Score of a window by how many of the mover's marks it already holds.
  static const List<double> _ownWeights = [1, 12, 120, 1200, 12000];

  /// Score of a window by how many opponent marks it holds, slightly below
  /// [_ownWeights] so attacking wins ties with defending.
  static const List<double> _opponentWeights = [0, 10, 100, 1000, 10000];

  static const double _centerWeight = 0.1;

  /// How much the human's best follow-up counts against a move in step 6.
  static const double _replyWeight = 0.5;

  final Difficulty difficulty;

  /// Overrides the table in difficulty_tuning.dart when set.
  final DifficultyTuning? tuning;

  final Duration timeBudget;
  final int searchWidth;
  final Random _random;

  @override
  Position chooseMove(Board board, Mark aiMark, Mark humanMark) {
    final clock = Stopwatch()..start();
    final grid = Grid.fromBoard(board, aiMark, humanMark);
    final candidates = _candidates(grid);
    if (candidates.isEmpty) throw StateError('The board is full');

    // 1. Win now.
    final wins = [
      for (final cell in candidates)
        if (grid.winsAt(cell, Grid.ai)) cell,
    ];
    if (wins.isNotEmpty) return _pick(grid, wins);

    // 2. Block an immediate loss.
    final blocks = [
      for (final cell in candidates)
        if (grid.winsAt(cell, Grid.human)) cell,
    ];

    if (difficulty == Difficulty.easy) {
      return _pick(grid, blocks.isNotEmpty ? blocks : candidates);
    }

    final active = tuning ?? tuningFor(difficulty, board.size);
    final scores = <int, double>{
      for (final cell in candidates)
        cell: _score(grid, cell, Grid.ai, lineDefence: active.lineDefence),
    };

    if (active.blunderChance > 0 &&
        _random.nextDouble() < active.blunderChance) {
      return _blunder(grid, candidates, scores, active.blunderPool);
    }

    if (blocks.isNotEmpty) return _best(grid, blocks, scores);

    // 3. Threats.
    final ownDoubles = [
      for (final cell in candidates)
        if (_winningCellsAfter(grid, cell, Grid.ai) >= 2) cell,
    ];
    if (ownDoubles.isNotEmpty) return _best(grid, ownDoubles, scores);

    final humanDoubles = [
      for (final cell in candidates)
        if (_winningCellsAfter(grid, cell, Grid.human) >= 2) cell,
    ];
    if (humanDoubles.isNotEmpty) return _best(grid, humanDoubles, scores);

    final openRuns = [
      for (final cell in candidates)
        if (_makesOpenRun(grid, cell, Grid.ai)) cell,
    ];
    if (openRuns.isNotEmpty) return _best(grid, openRuns, scores);

    // 4. Best heuristic score, the fallback for step 6.
    final heuristicBest = _bestIndex(candidates, scores);

    // 6. Depth-2 look at the strongest few candidates.
    final ranked = List<int>.of(candidates)
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    final top = ranked.take(searchWidth).toList();
    if (top.length < 2) return grid.positionOf(heuristicBest);

    final values = <int, double>{};
    for (final cell in top) {
      if (clock.elapsed >= timeBudget) return grid.positionOf(heuristicBest);
      grid.cells[cell] = Grid.ai;
      var reply = 0.0;
      for (final answer in _candidates(grid)) {
        final value = _score(grid, answer, Grid.human, offenceOnly: true);
        if (value > reply) reply = value;
      }
      grid.cells[cell] = Grid.empty;
      values[cell] = scores[cell]! - _replyWeight * active.lineDefence * reply;
    }
    return grid.positionOf(_bestIndex(top, values));
  }

  Position _pick(Grid grid, List<int> cells) =>
      grid.positionOf(cells[_random.nextInt(cells.length)]);

  /// A random one of the [pool] best scored [cells]. Equal scores are ordered
  /// at random. A blocking cell scores high, so it is usually in the pool,
  /// but it is not forced.
  Position _blunder(
    Grid grid,
    List<int> cells,
    Map<int, double> scores,
    int pool,
  ) {
    final ranked = [
      for (final cell in cells)
        (cell: cell, score: scores[cell]!, tie: _random.nextDouble()),
    ];
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.tie.compareTo(b.tie);
    });
    final top = min(pool, ranked.length);
    return grid.positionOf(ranked[_random.nextInt(top)].cell);
  }

  Position _best(Grid grid, List<int> cells, Map<int, double> scores) =>
      grid.positionOf(_bestIndex(cells, scores));

  /// The highest scoring of [cells]; ties are broken with the seeded random.
  int _bestIndex(List<int> cells, Map<int, double> scores) {
    var best = double.negativeInfinity;
    final ties = <int>[];
    for (final cell in cells) {
      final score = scores[cell]!;
      if (score > best) {
        best = score;
        ties
          ..clear()
          ..add(cell);
      } else if (score == best) {
        ties.add(cell);
      }
    }
    return ties[_random.nextInt(ties.length)];
  }

  /// Empty cells within [candidateRadius] of any mark, in index order. The
  /// centre on an empty board.
  List<int> _candidates(Grid grid) {
    final size = grid.size;
    final cells = grid.cells;
    final near = List<bool>.filled(cells.length, false);
    var anyMark = false;

    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == Grid.empty) continue;
      anyMark = true;
      final row = i ~/ size;
      final col = i % size;
      final rowEnd = min(size - 1, row + candidateRadius);
      final colEnd = min(size - 1, col + candidateRadius);
      for (var r = max(0, row - candidateRadius); r <= rowEnd; r++) {
        for (var c = max(0, col - candidateRadius); c <= colEnd; c++) {
          near[r * size + c] = true;
        }
      }
    }

    if (!anyMark) {
      final middle = size ~/ 2;
      return [middle * size + middle];
    }

    final result = [
      for (var i = 0; i < cells.length; i++)
        if (near[i] && cells[i] == Grid.empty) i,
    ];
    // Only when every cell near a mark is taken; fall back to any empty cell.
    return result.isNotEmpty ? result : grid.emptyIndices;
  }

  /// Line-window score of [who] playing the empty [cell].
  ///
  /// Every window of winLength cells through [cell] is counted unless it holds
  /// both players' marks. Fuller windows weigh far more. With [offenceOnly],
  /// windows that only hold opponent marks (the blocking value) are skipped.
  /// [lineDefence] scales the blocking value of windows that are not yet an
  /// immediate threat; a window one mark from winning always counts in full.
  double _score(
    Grid grid,
    int cell,
    int who, {
    bool offenceOnly = false,
    double lineDefence = 1,
  }) {
    final size = grid.size;
    final length = grid.winLength;
    final cells = grid.cells;
    final row = cell ~/ size;
    final col = cell % size;
    var score = 0.0;

    for (var d = 0; d < 4; d++) {
      final dRow = Grid.rowSteps[d];
      final dCol = Grid.colSteps[d];
      for (var offset = 0; offset < length; offset++) {
        final startRow = row - offset * dRow;
        final startCol = col - offset * dCol;
        final endRow = startRow + (length - 1) * dRow;
        final endCol = startCol + (length - 1) * dCol;
        if (!grid.inBounds(startRow, startCol) ||
            !grid.inBounds(endRow, endCol)) {
          continue;
        }

        var own = 0;
        var other = 0;
        for (var k = 0; k < length; k++) {
          final value =
              cells[(startRow + k * dRow) * size + startCol + k * dCol];
          if (value == who) {
            own++;
          } else if (value != Grid.empty) {
            other++;
          }
        }
        if (own > 0 && other > 0) continue;
        if (other == 0) {
          score += _ownWeights[own];
        } else if (!offenceOnly) {
          final urgent = other >= length - 1;
          score += _opponentWeights[other] * (urgent ? 1 : lineDefence);
        }
      }
    }

    final middle = (size - 1) / 2;
    final fromCentre = (row - middle).abs() + (col - middle).abs();
    return score + _centerWeight * (size - 1 - fromCentre);
  }

  /// How many different cells [who] could win on next turn after playing
  /// [cell]. Two or more cannot both be blocked.
  int _winningCellsAfter(Grid grid, int cell, int who) {
    final size = grid.size;
    final cells = grid.cells;
    final row = cell ~/ size;
    final col = cell % size;
    final reach = grid.winLength - 1;
    var count = 0;

    cells[cell] = who;
    for (var d = 0; d < 4; d++) {
      for (var step = -reach; step <= reach; step++) {
        if (step == 0) continue;
        final r = row + step * Grid.rowSteps[d];
        final c = col + step * Grid.colSteps[d];
        if (!grid.inBounds(r, c)) continue;
        final index = r * size + c;
        if (cells[index] == Grid.empty && grid.winsAt(index, who)) count++;
      }
    }
    cells[cell] = Grid.empty;
    return count;
  }

  /// Whether [who] playing [cell] makes a run of exactly winLength-2 with both
  /// ends empty and enough free room around it to grow past a single block.
  bool _makesOpenRun(Grid grid, int cell, int who) {
    final size = grid.size;
    final cells = grid.cells;
    final length = grid.winLength;
    final row = cell ~/ size;
    final col = cell % size;
    final blocker = Grid.opponentOf(who);

    for (var d = 0; d < 4; d++) {
      final dRow = Grid.rowSteps[d];
      final dCol = Grid.colSteps[d];
      final forward = grid.runLength(row, col, d, 1, who);
      final backward = grid.runLength(row, col, d, -1, who);
      if (1 + forward + backward != length - 2) continue;

      // Free cells beyond each end, up to the next opponent mark or the edge.
      var room = length - 2;
      var bothEndsOpen = true;
      for (final sign in const [1, -1]) {
        final run = sign == 1 ? forward : backward;
        var r = row + sign * (run + 1) * dRow;
        var c = col + sign * (run + 1) * dCol;
        if (!grid.inBounds(r, c) || cells[r * size + c] != Grid.empty) {
          bothEndsOpen = false;
          break;
        }
        while (grid.inBounds(r, c) && cells[r * size + c] != blocker) {
          room++;
          r += sign * dRow;
          c += sign * dCol;
        }
      }
      if (bothEndsOpen && room > length) return true;
    }
    return false;
  }
}
