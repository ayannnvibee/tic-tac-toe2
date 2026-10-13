import 'dart:math' as math;

import 'player.dart';

/// Board size of the first round of a session, and after any full reset.
const int initialBoardSize = 3;

/// The win length never grows past this, however large the board gets.
const int maxWinLength = 5;

/// Who moves first in every round. Kept as the single place to change if the
/// opening move should ever alternate or go to the previous round's loser.
const Player firstPlayerOfRound = Player.human;

/// Consecutive marks needed to win on a board of [size]:
/// 3 on 3x3, 4 on 4x4, 5 on 5x5 and larger.
int winLengthFor(int size) => math.min(size, maxWinLength);
