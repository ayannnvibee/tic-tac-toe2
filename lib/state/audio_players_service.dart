import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'feedback.dart';

/// [AudioService] backed by the audioplayers package.
///
/// Each effect gets a small pool of players that already hold the sound, so
/// playing it is immediate. Audio is never essential: any failure to load or
/// play is swallowed and the game carries on silently.
class AudioPlayersAudioService implements AudioService {
  final Map<SoundEffect, AudioPool> _pools = {};
  Future<void>? _loading;
  bool _disposed = false;

  @override
  Future<void> preload() => _loading ??= _load();

  Future<void> _load() async {
    try {
      // Short effects should play over the user's music, not pause it.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
    } catch (_) {
      // Keep the platform default.
    }

    for (final effect in SoundEffect.values) {
      try {
        final pool = await AudioPool.createFromAsset(
          path: 'sounds/${effect.name}.wav',
          // Two marks can land close together: the human's, then the reply.
          maxPlayers: effect == SoundEffect.place ? 2 : 1,
        );
        if (_disposed) {
          await pool.dispose();
        } else {
          _pools[effect] = pool;
        }
      } catch (_) {
        // This effect stays silent.
      }
    }
  }

  @override
  void play(SoundEffect effect) => unawaited(_play(effect));

  Future<void> _play(SoundEffect effect) async {
    try {
      await preload();
      if (_disposed) return;
      await _pools[effect]?.start();
    } catch (_) {
      // Nothing to do: the move has already been made.
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final pools = _pools.values.toList();
    _pools.clear();
    for (final pool in pools) {
      try {
        await pool.dispose();
      } catch (_) {
        // Already gone.
      }
    }
  }
}
