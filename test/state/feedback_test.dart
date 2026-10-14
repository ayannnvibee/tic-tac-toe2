import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import 'fake_ai.dart';

void main() {
  late FakeAi ai;
  late FakeAudio audio;
  late FakeHaptics haptics;
  late ProviderContainer container;

  setUp(() {
    ai = FakeAi();
    audio = FakeAudio();
    haptics = FakeHaptics();
    container = createContainer(ai, audio: audio, haptics: haptics);
  });

  test('sounds are preloaded when the game starts', () {
    expectInitial(container.game);
    expect(audio.preloads, 1);
    expect(audio.played, isEmpty);
    expect(haptics.events, isEmpty);
  });

  group('switched on', () {
    test('a human move clicks, and both marks make the place sound', () async {
      await container.controller.onCellTapped(const Position(0, 0));

      expect(haptics.events, ['selectionClick']);
      expect(audio.played, [SoundEffect.place, SoundEffect.place]);
    });

    test('a human win plays win and gives the round end impact', () async {
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);

      expect(audio.played.last, SoundEffect.win);
      expect(audio.played.where((effect) => effect == SoundEffect.win), [
        SoundEffect.win,
      ]);
      // Three human moves, the last of which ended the round.
      expect(haptics.events, [
        'selectionClick',
        'selectionClick',
        'selectionClick',
        'mediumImpact',
      ]);
    });

    test('a computer win plays lose and gives the round end impact', () async {
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);

      expect(audio.played.last, SoundEffect.lose);
      expect(haptics.events.last, 'mediumImpact');
      expect(haptics.events.where((event) => event == 'mediumImpact'), [
        'mediumImpact',
      ]);
      expect(haptics.events.where((event) => event == 'selectionClick'), [
        'selectionClick',
        'selectionClick',
        'selectionClick',
      ]);
    });

    test('a draw plays draw and gives the round end impact', () async {
      ai.script.addAll(drawReplies);
      await container.tapAll(drawTaps);

      expect(audio.played.last, SoundEffect.draw);
      expect(haptics.events.last, 'mediumImpact');
    });

    test('ignored taps give no feedback', () async {
      ai.script.add(const Position(1, 1));
      await container.controller.onCellTapped(const Position(0, 0));
      final sounds = audio.played.length;
      final buzzes = haptics.events.length;

      // Occupied, then off the board.
      await container.controller.onCellTapped(const Position(0, 0));
      await container.controller.onCellTapped(const Position(1, 1));
      await container.controller.onCellTapped(const Position(7, 7));
      expect(audio.played, hasLength(sounds));
      expect(haptics.events, hasLength(buzzes));
    });

    test('a move discarded by New Game makes no sound', () async {
      ai.hold = true;
      final turn = container.controller.onCellTapped(const Position(0, 0));
      expect(audio.played, [SoundEffect.place]);

      container.controller.newGame();
      ai.release(0, const Position(1, 1));
      await turn;
      expect(audio.played, [SoundEffect.place]);
    });
  });

  group('switched off', () {
    test('no sound when sound is off, haptics still work', () async {
      container.controller.toggleSound();
      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);

      expect(audio.played, isEmpty);
      expect(haptics.events, isNotEmpty);
    });

    test('no haptics when haptics are off, sound still works', () async {
      container.controller.toggleHaptics();
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);

      expect(haptics.events, isEmpty);
      expect(audio.played, isNotEmpty);
    });

    test('nothing at all when both are off, for every outcome', () async {
      container.controller
        ..toggleSound()
        ..toggleHaptics();

      ai.script.addAll(humanWinReplies);
      await container.tapAll(humanWinTaps);
      container.controller.newGame();
      ai.script.addAll(computerWinReplies);
      await container.tapAll(computerWinTaps);
      container.controller.newGame();
      ai.script.addAll(drawReplies);
      await container.tapAll(drawTaps);

      expect(audio.played, isEmpty);
      expect(haptics.events, isEmpty);
    });

    test('switching back on restores feedback', () async {
      container.controller
        ..toggleSound()
        ..toggleHaptics()
        ..toggleSound()
        ..toggleHaptics();
      await container.controller.onCellTapped(const Position(0, 0));

      expect(audio.played, isNotEmpty);
      expect(haptics.events, ['selectionClick']);
    });
  });

  group('sound files', () {
    for (final effect in SoundEffect.values) {
      test('${effect.name}.wav is a small WAV file', () {
        final file = File('assets/sounds/${effect.name}.wav');
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), lessThan(50 * 1024));

        final bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
        // More than a header: there is sound in it.
        expect(bytes.length, greaterThan(1000));
      });
    }

    test('the generator script and the asset folder are in place', () {
      expect(File('tool/generate_sounds.dart').existsSync(), isTrue);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/sounds/'),
      );
    });
  });
}
