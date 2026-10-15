import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The looping background track on the Game screen. Whether music is
/// switched on, and when it should be heard, is the Game screen's business.
abstract class MusicService {
  /// Starts the loop, or resumes it where it was paused.
  void play();

  /// Stops the loop, keeping its position.
  void pause();

  Future<void> dispose();
}

/// [MusicService] backed by audioplayers. Failures are swallowed: the game
/// simply stays quiet.
class AudioPlayersMusicService implements MusicService {
  /// Quiet enough to sit under the sound effects.
  static const double volume = 0.25;

  static const String asset = 'music/game_loop.wav';

  AudioPlayer? _player;
  bool _started = false;
  bool _disposed = false;

  AudioPlayer _ensurePlayer() => _player ??= AudioPlayer();

  @override
  void play() => unawaited(_play());

  Future<void> _play() async {
    if (_disposed) return;
    try {
      final player = _ensurePlayer();
      if (_started) {
        await player.resume();
        return;
      }
      _started = true;
      // Music should mix with the effects and the user's own audio.
      await player.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (_) {
      // Stay quiet.
    }
  }

  @override
  void pause() {
    final player = _player;
    if (player == null || _disposed) return;
    unawaited(player.pause().catchError((Object _) {}));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await _player?.dispose();
    } catch (_) {
      // Already gone.
    }
  }
}

/// Tests override this with a fake.
final musicServiceProvider = Provider<MusicService>((ref) {
  final service = AudioPlayersMusicService();
  ref.onDispose(service.dispose);
  return service;
});
