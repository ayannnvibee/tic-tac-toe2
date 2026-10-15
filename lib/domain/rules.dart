import 'player.dart';

/// Board size of the first round of a session, and after any full reset.
const int initialBoardSize = 3;

/// The win length never grows past this, however large the board gets.
const int maxWinLength = 5;

/// Who moves first in every round. Kept as the single place to change if the
/// opening move should ever alternate or go to the previous round's loser.
const Player firstPlayerOfRound = Player.human;

/// Consecutive marks needed to win on a board of [size]:
/// 3 on 3x3 and 4x4, 4 on 5x5, 5 on 6x6 and larger.
///
/// From 4x4 up the line is shorter than the board, so a win does not need a
/// whole row and one computer mark cannot shut a line down for good.
int winLengthFor(int size) => switch (size) {
  <= 4 => 3,
  5 => 4,
  _ => maxWinLength,
};
