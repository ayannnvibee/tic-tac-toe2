import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai.dart';
import '../domain/domain.dart';
import 'ad_config.dart';
import 'ad_service.dart';
import 'feedback.dart';
import 'game_state.dart';

/// Computes the computer's move for a request.
typedef AiMoveFunction = Future<Position> Function(AiRequest request);

/// Runs the engine on another isolate so large boards never block the UI.
Future<Position> computeAiMoveInIsolate(AiRequest request) =>
    Isolate.run(() => computeAiMove(request));

/// How the computer's move is computed. Tests override this with a fake.
final aiMoveFunctionProvider = Provider<AiMoveFunction>(
  (ref) => computeAiMoveInIsolate,
);

/// The generator the controller draws a new seed from for every AI move.
final aiSeedRandomProvider = Provider<Random>((ref) => Random());

/// The shortest time an AI turn takes, so the reply does not feel instant.
final aiMoveDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 300),
);

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Owns the game: applies human taps, runs the computer's turns and moves the
/// session from round to round. Widgets call these methods and nothing else.
class GameController extends Notifier<GameState> {
  late Random _seedRandom;
  final Set<int> _usedSeeds = {};

  /// Bumped whenever the round in play is replaced, so an AI move that was
  /// requested for an earlier round can be recognised and dropped.
  int _generation = 0;

  /// Rounds finished since the last full-screen ad.
  int _finishedRounds = 0;

  /// The round as it was just before the human's latest move. A rewarded
  /// second chance after a loss goes back to it.
  RoundState? _beforeHumanMove;

  @override
  GameState build() {
    _seedRandom = ref.watch(aiSeedRandomProvider);
    ref.onDispose(() => _generation++);
    // Load the sounds now so the first tap is not delayed by it.
    unawaited(ref.watch(audioServiceProvider).preload());
    // Ads load in the background; the game never waits for them.
    unawaited(ref.watch(adServiceProvider).initialize());

    final initial = GameState.initial();
    _startComputerIfItOpens(initial);
    return initial;
  }

  /// Plays the human's mark at [position] and then lets the computer reply.
  ///
  /// Ignored when it is not the human's turn, the computer is thinking, the
  /// round is over or the cell is taken. The returned future completes once
  /// the computer's reply, if any, is on the board.
  Future<void> onCellTapped(Position position) async {
    final round = state.session.round;
    if (state.isAiThinking ||
        state.pendingResult != null ||
        round.isOver ||
        round.currentTurn != Player.human) {
      return;
    }

    final result = round.applyMove(position);
    if (result is! MoveAccepted) return;

    _beforeHumanMove = round;
    _showRound(result.state);
    _giveFeedback(result.state, byHuman: true);
    if (!result.state.isOver) await _runAiTurn();
  }

  /// Starts the round that follows the finished one: a bigger board after a
  /// human win, the same size after a computer win, a full reset after a
  /// draw. Does nothing while a round is still being played.
  ///
  /// Every [AdConfig.roundsPerInterstitial] finished rounds an interstitial is
  /// shown first; the next round starts once it is closed, or at once when no
  /// ad is loaded.
  Future<void> continueToNextRound() async {
    final result = state.pendingResult;
    if (result == null || state.isShowingAd) return;

    if (_finishedRounds >= AdConfig.roundsPerInterstitial) {
      _finishedRounds = 0;
      final roundId = state.roundId;
      state = state.copyWith(isShowingAd: true);
      await ref.read(adServiceProvider).showInterstitial();
      if (!ref.mounted) return;
      state = state.copyWith(isShowingAd: false);
      // New Game may have replaced the round while the ad was up.
      if (state.roundId != roundId || state.pendingResult != result) return;
    }

    _generation++;
    _beforeHumanMove = null;
    state = state.copyWith(
      session: state.session.nextRoundAfter(result),
      isAiThinking: false,
      pendingResult: null,
      roundId: state.roundId + 1,
    );
    _startComputerIfItOpens(state);
  }

  /// Full reset to 3x3 and 0/0. Any AI move still being computed is dropped.
  /// Difficulty, sound and haptics are kept.
  void newGame() {
    _generation++;
    _beforeHumanMove = null;
    state = state.copyWith(
      session: state.session.newGame(),
      isAiThinking: false,
      pendingResult: null,
      roundId: state.roundId + 1,
    );
    _startComputerIfItOpens(state);
  }

  void setDifficulty(Difficulty difficulty) =>
      state = state.copyWith(difficulty: difficulty);

  void toggleSound() =>
      state = state.copyWith(soundEnabled: !state.soundEnabled);

  void toggleMusic() =>
      state = state.copyWith(musicEnabled: !state.musicEnabled);

  /// Whether a rewarded ad can rescue a round that ended with [result]: a
  /// loss is undone, a draw keeps the level instead of resetting to 3x3.
  static bool canContinueWithAd(RoundStatus? result) =>
      result == RoundStatus.computerWon || result == RoundStatus.draw;

  /// Shows a rewarded ad for the finished round. If the player earns the
  /// reward, a loss is taken back to just before their last move and the
  /// same round goes on; a draw starts a fresh board of the same size with
  /// both scores kept. Without the reward nothing changes and the result card
  /// stays up. Watching resets the interstitial count, so two ads never run
  /// back to back.
  Future<void> watchAdToContinue() async {
    final result = state.pendingResult;
    if (!canContinueWithAd(result) || state.isShowingAd) return;

    final roundId = state.roundId;
    state = state.copyWith(isShowingAd: true);
    final earned = await ref.read(adServiceProvider).showRewarded();
    if (!ref.mounted) return;
    state = state.copyWith(isShowingAd: false);
    if (!earned || state.roundId != roundId || state.pendingResult != result) {
      return;
    }

    _finishedRounds = 0;
    if (result == RoundStatus.computerWon) {
      final before = _beforeHumanMove;
      if (before == null) return;
      _generation++;
      state = state.copyWith(
        session: state.session.withRound(before),
        isAiThinking: false,
        pendingResult: null,
      );
    } else {
      _generation++;
      _beforeHumanMove = null;
      state = state.copyWith(
        session: state.session.replaySameSize(),
        isAiThinking: false,
        pendingResult: null,
        roundId: state.roundId + 1,
      );
    }
  }

  void toggleHaptics() =>
      state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);

  /// Shows [round] on the board, and its result if it has just ended.
  void _showRound(RoundState round) {
    if (round.isOver) _finishedRounds++;
    state = state.copyWith(
      session: state.session.withRound(round),
      isAiThinking: false,
      pendingResult: round.isOver ? round.status : null,
    );
  }

  /// Only matters if `firstPlayerOfRound` is ever changed to the computer.
  void _startComputerIfItOpens(GameState fresh) {
    if (fresh.session.round.currentTurn != Player.computer) return;
    final generation = _generation;
    scheduleMicrotask(() {
      if (generation == _generation && !state.isAiThinking) {
        unawaited(_runAiTurn());
      }
    });
  }

  Future<void> _runAiTurn() async {
    final generation = _generation;
    final request = AiRequest.fromBoard(
      state.session.round.board,
      seed: _nextSeed(),
      difficulty: state.difficulty,
      aiMark: Player.computer.mark,
    );
    final compute = ref.read(aiMoveFunctionProvider);
    final delay = ref.read(aiMoveDelayProvider);
    state = state.copyWith(isAiThinking: true);

    final minimumWait = delay > Duration.zero
        ? Future<void>.delayed(delay)
        : null;
    Position? move;
    try {
      move = await compute(request);
    } catch (_) {
      // Handled below: the turn must still end with exactly one move.
    }
    if (minimumWait != null) await minimumWait;

    // New Game, a new round or disposal happened while the AI was thinking.
    if (generation != _generation) return;

    final round = state.session.round;
    var result = move == null ? null : round.applyMove(move);
    if (result is! MoveAccepted) {
      // The engine failed or answered with an illegal cell. Play any legal
      // move so the game cannot get stuck on the computer's turn.
      result = round.applyMove(round.board.emptyCells.first);
    }
    if (result is MoveAccepted) {
      _showRound(result.state);
      _giveFeedback(result.state, byHuman: false);
    }
  }

  /// Sound and haptics for a move that has just been shown, each only when
  /// its switch is on. [round] is the round after the move.
  void _giveFeedback(RoundState round, {required bool byHuman}) {
    if (state.hapticsEnabled) {
      final haptics = ref.read(hapticsServiceProvider);
      if (byHuman) haptics.selectionClick();
      if (round.isOver) haptics.mediumImpact();
    }
    if (state.soundEnabled) {
      final audio = ref.read(audioServiceProvider);
      audio.play(switch (round.status) {
        RoundStatus.inProgress => SoundEffect.place,
        RoundStatus.humanWon => SoundEffect.win,
        RoundStatus.computerWon => SoundEffect.lose,
        RoundStatus.draw => SoundEffect.draw,
      });
    }
  }

  /// A seed that has not been used before in this controller's lifetime.
  int _nextSeed() {
    int seed;
    do {
      seed = _seedRandom.nextInt(1 << 32);
    } while (!_usedSeeds.add(seed));
    return seed;
  }
}
