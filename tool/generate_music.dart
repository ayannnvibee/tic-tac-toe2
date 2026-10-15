// Generates the calm background loop played on the Game screen.
//
// Synthesized here from sine tones, so there is nothing to license. Run from
// the project root to regenerate it:
//
//     dart run tool/generate_music.dart
//
// Output: assets/music/game_loop.wav (16 kHz, 16-bit, mono, 24 s, ~750 KB).
// Every note is written into a circular buffer, so tails that run past the
// end wrap to the start and the loop has no seam.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 16000;
const String outputPath = 'assets/music/game_loop.wav';

/// 80 beats per minute.
const double beat = 0.75;

/// Eight beats per chord, four chords: 24 seconds.
const int beatsPerChord = 8;

double hz(int midi) => 440.0 * pow(2, (midi - 69) / 12);

/// C, A minor, F, G: root position triads around middle C, as MIDI notes.
const List<List<int>> chords = [
  [48, 55, 60, 64], // C
  [45, 52, 57, 60], // Am
  [41, 53, 57, 60], // F
  [43, 50, 55, 59], // G
];

/// The arpeggio walks these chord tones an octave up, one per half beat.
const List<int> arpeggio = [0, 1, 2, 3, 2, 1, 2, 3];

final int totalSamples = (sampleRate * beat * beatsPerChord * chords.length)
    .round();
final Float64List buffer = Float64List(totalSamples);

/// Adds a tone into the loop at [startSeconds], wrapping past the end.
void addTone({
  required double frequency,
  required double startSeconds,
  required double seconds,
  required double level,
  required double attack,
  required double release,
  double decay = 0,
}) {
  final start = (startSeconds * sampleRate).round();
  final count = (seconds * sampleRate).round();
  for (var i = 0; i < count; i++) {
    final t = i / sampleRate;
    final fadeIn = t < attack ? t / attack : 1.0;
    final left = seconds - t;
    final fadeOut = left < release ? left / release : 1.0;
    final envelope = fadeIn * fadeOut * exp(-decay * t);
    final phase = 2 * pi * frequency * t;
    final wave = sin(phase) + 0.15 * sin(2 * phase);
    buffer[(start + i) % totalSamples] += wave * envelope * level;
  }
}

Uint8List wav(Float64List samples) {
  const headerSize = 44;
  final dataSize = samples.length * 2;
  final bytes = ByteData(headerSize + dataSize);

  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM.
  bytes.setUint16(22, 1, Endian.little); // Mono.
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);

  var peak = 0.0;
  for (final sample in samples) {
    peak = max(peak, sample.abs());
  }
  // Normalised to 70% so the file has headroom; the app also plays it quietly.
  final gain = peak == 0 ? 0 : 0.7 / peak;
  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i] * gain).clamp(-1.0, 1.0);
    bytes.setInt16(headerSize + i * 2, (value * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  final chordSeconds = beat * beatsPerChord;
  for (var c = 0; c < chords.length; c++) {
    final chordStart = c * chordSeconds;

    // A soft pad that swells in and overlaps the next chord a little.
    for (final note in chords[c]) {
      addTone(
        frequency: hz(note),
        startSeconds: chordStart,
        seconds: chordSeconds + 1.2,
        level: 0.12,
        attack: 1.2,
        release: 1.6,
      );
    }

    // Gentle plucks on the half beats.
    final steps = beatsPerChord * 2;
    for (var s = 0; s < steps; s++) {
      final tone = chords[c][arpeggio[s % arpeggio.length]] + 12;
      addTone(
        frequency: hz(tone),
        startSeconds: chordStart + s * beat / 2,
        seconds: 1.4,
        level: 0.09,
        attack: 0.01,
        release: 0.3,
        decay: 3,
      );
    }
  }

  final file = File(outputPath)..createSync(recursive: true);
  file.writeAsBytesSync(wav(buffer));
  final kb = (file.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln('${file.path}: $kb KB');
}
