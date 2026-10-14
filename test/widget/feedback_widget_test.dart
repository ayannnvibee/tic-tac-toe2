import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import 'app_harness.dart';

void main() {
  testWidgets('sound and haptics fire when their switches are on', (
    tester,
  ) async {
    final audio = FakeAudio();
    final haptics = FakeHaptics();
    final ai = await pumpApp(tester, audio: audio, haptics: haptics);
    await tester.openGame();
    await tester.playRound(ai, humanWinTaps, humanWinReplies);

    expect(audio.played, contains(SoundEffect.place));
    expect(audio.played.last, SoundEffect.win);
    expect(haptics.events, contains('selectionClick'));
    expect(haptics.events.last, 'mediumImpact');
  });

  testWidgets('nothing fires after both are switched off in the app', (
    tester,
  ) async {
    final audio = FakeAudio();
    final haptics = FakeHaptics();
    final ai = await pumpApp(tester, audio: audio, haptics: haptics);

    // Sound off with the Home pill, haptics off on the guide's controls tab.
    await tester.tap(find.byKey(const ValueKey('home-sound-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('how-to-play')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-controls')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch-haptics')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.openGame();
    await tester.playRound(ai, humanWinTaps, humanWinReplies);
    await tester.continueFromResult();
    await tester.playRound(ai, draw4x4Taps, draw4x4Replies);
    await tester.continueFromResult();
    await tester.playRound(ai, computerWinTaps, computerWinReplies);

    expect(audio.played, isEmpty);
    expect(haptics.events, isEmpty);
  });

  testWidgets('the in-game sound button silences the next move', (
    tester,
  ) async {
    final audio = FakeAudio();
    final ai = await pumpApp(tester, audio: audio);
    await tester.openGame();

    await tester.tap(find.byKey(const ValueKey('game-sound-toggle')));
    await tester.pumpAndSettle();
    await tester.playRound(ai, computerWinTaps, computerWinReplies);
    expect(audio.played, isEmpty);
  });
}
