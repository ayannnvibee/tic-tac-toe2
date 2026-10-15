import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import 'fake_ai.dart';

void main() {
  late FakeAi ai;
  late FakeAds ads;

  /// Loses a 3x3 round: the computer takes the middle row.
  Future<void> loseRound(ProviderContainer container) async {
    ai.script.addAll(computerWinReplies);
    await container.tapAll(computerWinTaps);
    expect(container.game.pendingResult, RoundStatus.computerWon);
  }

  group('interstitial', () {
    setUp(() {
      ai = FakeAi();
      ads = FakeAds();
    });

    test('shows after every 4th finished round, whatever the result', () async {
      final container = createContainer(ai, ads: ads);

      // A win, a loss, a draw and a loss: four finished rounds.
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      await container.controller.continueToNextRound();
      ai.script.addAll(const [Position(3, 0), Position(3, 1), Position(3, 2)]);
      await container.tapAll(const [
        Position(0, 0),
        Position(0, 1),
        Position(1, 3),
      ]);
      expect(container.game.pendingResult, RoundStatus.computerWon);
      await container.controller.continueToNextRound();
      container.controller.newGame();
      ai.script.addAll(drawReplies);
      await container.tapAll(drawTaps);
      expect(container.game.pendingResult, RoundStatus.draw);
      await container.controller.continueToNextRound();
      expect(ads.interstitialsShown, 0);

      await loseRound(container);
      await container.controller.continueToNextRound();
      expect(ads.interstitialsShown, 1);
      // The next round still starts once the ad is closed.
      expect(container.game.pendingResult, isNull);
      expect(container.game.session.computerWins, 1);

      for (var i = 0; i < 3; i++) {
        await loseRound(container);
        await container.controller.continueToNextRound();
      }
      expect(ads.interstitialsShown, 1);
      await loseRound(container);
      await container.controller.continueToNextRound();
      expect(ads.interstitialsShown, 2);
    });

    test('offline: no ad loaded, the game simply carries on', () async {
      ads.interstitialLoaded = false;
      final container = createContainer(ai, ads: ads);

      for (var i = 0; i < 5; i++) {
        await loseRound(container);
        await container.controller.continueToNextRound();
        expect(container.game.pendingResult, isNull);
        expect(container.game.isShowingAd, isFalse);
      }
      expect(ads.interstitialsShown, 0);
      expect(container.game.session.computerWins, 5);
    });

    test('is flagged while it is open', () async {
      final container = createContainer(ai, ads: ads);
      for (var i = 0; i < 3; i++) {
        await loseRound(container);
        await container.controller.continueToNextRound();
      }
      await loseRound(container);

      ads.holdInterstitial = Completer<void>();
      final continuing = container.controller.continueToNextRound();
      await Future<void>.delayed(Duration.zero);
      expect(container.game.isShowingAd, isTrue);
      expect(container.game.pendingResult, RoundStatus.computerWon);

      ads.holdInterstitial!.complete();
      await continuing;
      expect(container.game.isShowingAd, isFalse);
      expect(container.game.pendingResult, isNull);
    });
  });

  group('rewarded continue', () {
    setUp(() {
      ai = FakeAi();
      ads = FakeAds(rewardedLoaded: true);
    });

    test(
      'after a loss, undoes the last two moves and the round goes on',
      () async {
        final container = createContainer(ai, ads: ads);
        await loseRound(container);
        final roundId = container.game.roundId;

        await container.controller.watchAdToContinue();

        expect(ads.rewardedShown, 1);
        final round = container.round;
        expect(container.game.pendingResult, isNull);
        expect(round.status, RoundStatus.inProgress);
        expect(round.currentTurn, Player.human);
        expect(round.board.cellAt(const Position(0, 0)), Mark.x);
        expect(round.board.cellAt(const Position(0, 1)), Mark.x);
        expect(round.board.cellAt(const Position(1, 0)), Mark.o);
        expect(round.board.cellAt(const Position(1, 1)), Mark.o);
        // The human's last move and the computer's winning move are gone.
        expect(round.board.cellAt(const Position(2, 2)), Mark.empty);
        expect(round.board.cellAt(const Position(1, 2)), Mark.empty);
        // Same round, same level, scores untouched.
        expect(container.game.roundId, roundId);
        expect(container.game.session.boardSize, 3);
        expect(container.game.session.computerWins, 0);

        // The player can block this time and play on.
        ai.script.add(const Position(2, 0));
        await container.controller.onCellTapped(const Position(1, 2));
        expect(container.board.cellAt(const Position(1, 2)), Mark.x);
        expect(container.board.cellAt(const Position(2, 0)), Mark.o);
      },
    );

    test('after a draw, keeps the board size and both scores', () async {
      final container = createContainer(ai, ads: ads);
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      await container.controller.continueToNextRound();
      expect(container.game.session.boardSize, 4);

      // XXOO / OOXX / XXOO / OOXX: a full 4x4 board with no three in a row.
      ai.script.addAll(const [
        Position(0, 2),
        Position(0, 3),
        Position(1, 0),
        Position(1, 1),
        Position(2, 2),
        Position(2, 3),
        Position(3, 0),
        Position(3, 1),
      ]);
      await container.tapAll(const [
        Position(0, 0),
        Position(0, 1),
        Position(1, 2),
        Position(1, 3),
        Position(2, 0),
        Position(2, 1),
        Position(3, 2),
        Position(3, 3),
      ]);
      expect(container.game.pendingResult, RoundStatus.draw);

      await container.controller.watchAdToContinue();

      expect(container.game.pendingResult, isNull);
      expect(container.game.session.boardSize, 4);
      expect(container.game.session.humanWins, 1);
      expect(container.game.session.computerWins, 0);
      expect(container.board, Board.empty(4));
    });

    test('without the reward, nothing changes', () async {
      ads.earnReward = false;
      final container = createContainer(ai, ads: ads);
      await loseRound(container);

      await container.controller.watchAdToContinue();
      expect(ads.rewardedShown, 1);
      expect(container.game.pendingResult, RoundStatus.computerWon);
      expect(container.round.status, RoundStatus.computerWon);

      // The normal button still does the normal thing.
      await container.controller.continueToNextRound();
      expect(container.game.session.computerWins, 1);
      expect(container.board, Board.empty(3));
    });

    test('with no rewarded ad loaded, nothing changes', () async {
      ads.rewardedReady.value = false;
      final container = createContainer(ai, ads: ads);
      await loseRound(container);

      await container.controller.watchAdToContinue();
      expect(ads.rewardedShown, 0);
      expect(container.game.pendingResult, RoundStatus.computerWon);
    });

    test('is not offered after a win', () async {
      final container = createContainer(ai, ads: ads);
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);

      expect(GameController.canContinueWithAd(RoundStatus.humanWon), isFalse);
      await container.controller.watchAdToContinue();
      expect(ads.rewardedShown, 0);
      expect(container.game.pendingResult, RoundStatus.humanWon);
    });

    test(
      'restarts the interstitial count, so ads never run back to back',
      () async {
        final container = createContainer(ai, ads: ads);
        for (var i = 0; i < 3; i++) {
          await loseRound(container);
          await container.controller.continueToNextRound();
        }
        // The 4th finished round is rescued with a rewarded ad...
        await loseRound(container);
        await container.controller.watchAdToContinue();
        // ...then lost again: only one round since the ad.
        ai.script.add(const Position(1, 2));
        await container.controller.onCellTapped(const Position(2, 2));
        expect(container.game.pendingResult, RoundStatus.computerWon);
        await container.controller.continueToNextRound();
        expect(ads.interstitialsShown, 0);
      },
    );
  });

  test('the music switch flips on its own, apart from sound', () {
    final container = createContainer(FakeAi());
    expect(container.game.musicEnabled, isTrue);
    container.controller.toggleMusic();
    expect(container.game.musicEnabled, isFalse);
    expect(container.game.soundEnabled, isTrue);
  });
}
