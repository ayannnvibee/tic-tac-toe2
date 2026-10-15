import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ui/widgets/result_overlay.dart';

import 'app_harness.dart';

final Finder _watchAd = find.byKey(const ValueKey('result-watch-ad'));
final Finder _overlay = find.byType(ResultOverlay);

void main() {
  group('rewarded ad button', () {
    testWidgets('after a loss: second chance continues the same round', (
      tester,
    ) async {
      final ads = FakeAds(rewardedLoaded: true);
      final ai = await pumpApp(tester, ads: ads);
      await tester.openGame();
      await tester.playRound(ai, computerWinTaps, computerWinReplies);

      expect(find.text(ResultOverlay.secondChanceLabel), findsOneWidget);
      expect(find.text('RETRY LEVEL'), findsOneWidget);

      await tester.ensureVisible(_watchAd);
      await tester.tap(_watchAd);
      await tester.pumpAndSettle();

      expect(_overlay, findsNothing);
      expect(xAt(0, 0), findsOneWidget);
      expect(oAt(1, 1), findsOneWidget);
      expect(xAt(2, 2), findsNothing);
      expect(oAt(1, 2), findsNothing);
      expect(textOf(tester, 'turn-label'), 'YOUR TURN');
      expect(textOf(tester, 'score-computer'), '0');
    });

    testWidgets('after a draw: keep your level replays the same size', (
      tester,
    ) async {
      final ads = FakeAds(rewardedLoaded: true);
      final ai = await pumpApp(tester, ads: ads, boardSize: 4);
      await tester.openGame();
      await tester.playRound(ai, draw4x4Taps, draw4x4Replies);

      expect(find.text(ResultOverlay.keepLevelLabel), findsOneWidget);
      await tester.ensureVisible(_watchAd);
      await tester.tap(_watchAd);
      await tester.pumpAndSettle();

      expect(_overlay, findsNothing);
      expect(textOf(tester, 'board-size'), '4 × 4');
      expect(allCells, findsNWidgets(16));
      expect(textOf(tester, 'score-human'), '1');
    });

    testWidgets('hidden when no rewarded ad is loaded', (tester) async {
      final ai = await pumpApp(tester);
      await tester.openGame();
      await tester.playRound(ai, computerWinTaps, computerWinReplies);
      expect(_overlay, findsOneWidget);
      expect(_watchAd, findsNothing);
    });

    testWidgets('never offered after a win', (tester) async {
      final ai = await pumpApp(tester, ads: FakeAds(rewardedLoaded: true));
      await tester.openGame();
      await tester.playRound(ai, humanWinTaps, humanWinReplies);
      expect(_overlay, findsOneWidget);
      expect(_watchAd, findsNothing);
    });
  });

  group('music', () {
    testWidgets('plays in the game and stops on the way back Home', (
      tester,
    ) async {
      final music = FakeMusic();
      await pumpApp(tester, music: music);
      expect(music.events, isEmpty);

      await tester.openGame();
      expect(music.playing, isTrue);

      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(music.playing, isFalse);
    });

    testWidgets('the music button switches it off and on', (tester) async {
      final music = FakeMusic();
      await pumpApp(tester, music: music);
      await tester.openGame();

      await tester.tap(find.byKey(const ValueKey('game-music-toggle')));
      await tester.pumpAndSettle();
      expect(music.playing, isFalse);
      expect(find.byTooltip('Turn music on'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('game-music-toggle')));
      await tester.pumpAndSettle();
      expect(music.playing, isTrue);
    });

    testWidgets('pauses while an ad is showing', (tester) async {
      final music = FakeMusic();
      final ads = FakeAds()..holdInterstitial = Completer<void>();
      final ai = await pumpApp(tester, music: music, ads: ads);
      await tester.openGame();

      // Four finished rounds bring the interstitial.
      for (var i = 0; i < 3; i++) {
        await tester.playRound(ai, computerWinTaps, computerWinReplies);
        await tester.continueFromResult();
      }
      await tester.playRound(ai, computerWinTaps, computerWinReplies);
      expect(music.playing, isTrue);

      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      expect(ads.interstitialsShown, 1);
      expect(music.playing, isFalse);
      // The card waits behind the ad.
      expect(_overlay, findsOneWidget);

      ads.holdInterstitial!.complete();
      await tester.pumpAndSettle();
      expect(music.playing, isTrue);
      expect(_overlay, findsNothing);
      expect(textOf(tester, 'score-computer'), '4');
    });

    testWidgets('pauses when the app goes to the background', (tester) async {
      final music = FakeMusic();
      await pumpApp(tester, music: music);
      await tester.openGame();
      expect(music.playing, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(music.playing, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(music.playing, isTrue);
    });
  });

  testWidgets('without internet nothing blocks: rounds keep flowing', (
    tester,
  ) async {
    final ads = FakeAds()..interstitialLoaded = false;
    final ai = await pumpApp(tester, ads: ads);
    await tester.openGame();
    for (var i = 0; i < 5; i++) {
      await tester.playRound(ai, computerWinTaps, computerWinReplies);
      expect(_watchAd, findsNothing);
      await tester.continueFromResult();
      expect(_overlay, findsNothing);
    }
    expect(textOf(tester, 'score-computer'), '5');
    expect(tester.takeException(), isNull);
    expect(xAt(0, 0), findsNothing);
  });
}
