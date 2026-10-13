import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'game_controller.dart';

/// The labels [turnLabelProvider] can show.
abstract final class TurnLabels {
  static const String yourTurn = 'Your turn';
  static const String computerThinking = 'Computer is thinking...';
  static const String youWin = 'You Win';
  static const String computerWins = 'Computer Wins';
  static const String draw = 'Draw';
}

/// The side length of the board in play.
final boardSizeProvider = Provider<int>(
  (ref) => ref.watch(
    gameControllerProvider.select((state) => state.session.boardSize),
  ),
);

/// How many marks in a row win on the board in play.
final winLengthProvider = Provider<int>(
  (ref) => winLengthFor(ref.watch(boardSizeProvider)),
);

/// Rounds won by each side in this session.
final scoreProvider = Provider<({int humanWins, int computerWins})>(
  (ref) => ref.watch(
    gameControllerProvider.select(
      (state) => (
        humanWins: state.session.humanWins,
        computerWins: state.session.computerWins,
      ),
    ),
  ),
);

/// The one-line status shown above the board.
final turnLabelProvider = Provider<String>((ref) {
  final state = ref.watch(gameControllerProvider);
  return switch (state.pendingResult ?? state.session.round.status) {
    RoundStatus.humanWon => TurnLabels.youWin,
    RoundStatus.computerWon => TurnLabels.computerWins,
    RoundStatus.draw => TurnLabels.draw,
    RoundStatus.inProgress =>
      state.isAiThinking || state.session.round.currentTurn == Player.computer
          ? TurnLabels.computerThinking
          : TurnLabels.yourTurn,
  };
});
