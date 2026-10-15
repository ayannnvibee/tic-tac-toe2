import 'ai_player.dart';

/// Every number that decides how hard the computer is to beat lives in this
/// file. The measured results of the current values are recorded in CLAUDE.md
/// under "Difficulty tuning"; re-run test/ai/balance_test.dart after a change.

/// How often and how badly the computer slips on one board size.
class DifficultyTuning {
  const DifficultyTuning({
    this.blunderChance = 0,
    this.blunderPool = 1,
    this.lineDefence = 1,
  }) : assert(blunderChance >= 0 && blunderChance <= 1),
       assert(blunderPool >= 1),
       assert(lineDefence >= 0 && lineDefence <= 1);

  /// Chance, per move, that the computer blunders instead of playing its
  /// best move. It still takes an immediate win when one exists.
  final double blunderChance;

  /// A blunder plays a random one of this many best scored moves. It skips
  /// the block and threat rules, so it can miss a block.
  final int blunderPool;

  /// How eagerly the computer spoils the human's lines before they become an
  /// immediate threat, from 0 (never) to 1 (always). Larger boards only.
  ///
  /// At 1 the computer spoils lines early, which on 6x6 and larger draws
  /// almost every game; lower values let the human build a real threat,
  /// which the computer then blocks unless it blunders.
  final double lineDefence;
}

/// Perfect play on 3x3, and the full rule set on larger boards.
const DifficultyTuning noBlunders = DifficultyTuning();

/// Medium, by board size. Sizes not listed use [mediumLargeBoardTuning].
const Map<int, DifficultyTuning> mediumTuningBySize = {
  3: DifficultyTuning(blunderChance: 0.25, blunderPool: 5),
  // 3 in a row on 4x4 and 4 in a row on 5x5 favour the first player, so the
  // computer plays close to its best there and the human still wins most.
  4: DifficultyTuning(blunderChance: 0.10, blunderPool: 3),
  5: DifficultyTuning(blunderChance: 0.10, blunderPool: 3),
  6: DifficultyTuning(blunderChance: 0.35, blunderPool: 3, lineDefence: 0.05),
};

/// Medium on 7x7 and larger. Full line defence there drew almost every game,
/// so it is turned down like on 6x6.
const DifficultyTuning mediumLargeBoardTuning = DifficultyTuning(
  blunderChance: 0.20,
  blunderPool: 4,
  lineDefence: 0.05,
);

/// The tuning for [difficulty] on a board of [boardSize].
///
/// Hard never blunders. Easy does not use this table: it wins and blocks,
/// and otherwise plays a random nearby cell.
DifficultyTuning tuningFor(Difficulty difficulty, int boardSize) =>
    switch (difficulty) {
      Difficulty.medium =>
        mediumTuningBySize[boardSize] ?? mediumLargeBoardTuning,
      Difficulty.easy || Difficulty.hard => noBlunders,
    };

/// Time the depth-2 search on large boards may use before it falls back to
/// the best heuristic move. Kept below the 150 ms ceiling for a whole move.
const Duration aiTimeBudget = Duration(milliseconds: 100);

/// How many of the best candidates the depth-2 search looks at.
const int aiSearchWidth = 8;

/// Large boards only consider empty cells this close to an existing mark.
const int aiCandidateRadius = 2;
