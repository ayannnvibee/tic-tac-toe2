// Generates the game's sound effects as small WAV files.
//
// Every sound is synthesized here from sine tones, so there is nothing to
// license. Run from the project root to regenerate them:
//
//     dart run tool/generate_sounds.dart
//
// Output: assets/sounds/place.wav, win.wav, lose.wav and draw.wav
// (22.05 kHz, 16-bit, mono, each well under 50 KB).

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;
const String outputDir = 'assets/sounds';

/// One tone: it glides from [startHz] to [endHz] over [ms] milliseconds.
class Note {
  const Note(this.startHz, this.ms, {double? endHz, this.gapMs = 0})
    : endHz = endHz ?? startHz;

  final double startHz;
  final double endHz;
  final int ms;

  /// Silence after the note.
  final int gapMs;
}

// Note frequencies in hertz.
const double c4 = 261.63;
const double e4 = 329.63;
const double g4 = 392.00;
const double a4 = 440.00;
const double c5 = 523.25;
const double e5 = 659.25;
const double g5 = 783.99;
const double c6 = 1046.50;

const Map<String, List<Note>> sounds = {
  // A short rising pop when a mark lands.
  'place': [Note(520, 90, endHz: 780)],
  // A rising major arpeggio.
  'win': [Note(c5, 110), Note(e5, 110), Note(g5, 110), Note(c6, 260)],
  // A gentle falling phrase; soft, not punishing.
  'lose': [Note(g4, 150), Note(e4, 150), Note(c4, 280)],
  // Two even notes: nobody won.
  'draw': [Note(a4, 120, gapMs: 40), Note(a4, 160)],
};

/// Samples for [note] in the range -1..1, with a soft attack and a decay so
/// notes do not click.
List<double> render(Note note) {
  final count = sampleRate * note.ms ~/ 1000;
  final attack = sampleRate * 5 ~/ 1000;
  final samples = List<double>.filled(
    count + sampleRate * note.gapMs ~/ 1000,
    0,
  );

  var phase = 0.0;
  for (var i = 0; i < count; i++) {
    final progress = i / count;
    final hz = note.startHz + (note.endHz - note.startHz) * progress;
    phase += 2 * pi * hz / sampleRate;

    final fadeIn = i < attack ? i / attack : 1.0;
    final decay = exp(-3.5 * progress);
    final fadeOut = progress > 0.9 ? (1 - progress) / 0.1 : 1.0;

    // A little second and third harmonic makes the tone rounder than a bare
    // sine without sounding harsh.
    final wave = sin(phase) + 0.25 * sin(2 * phase) + 0.1 * sin(3 * phase);
    samples[i] = wave / 1.35 * fadeIn * decay * fadeOut;
  }
  return samples;
}

/// A complete mono 16-bit PCM WAV file holding [samples].
Uint8List wav(List<double> samples) {
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
  bytes.setUint32(16, 16, Endian.little); // Size of the fmt chunk.
  bytes.setUint16(20, 1, Endian.little); // PCM.
  bytes.setUint16(22, 1, Endian.little); // Mono.
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little); // Bytes per second.
  bytes.setUint16(32, 2, Endian.little); // Bytes per sample frame.
  bytes.setUint16(34, 16, Endian.little); // Bits per sample.
  ascii(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);

  const volume = 0.6;
  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i] * volume).clamp(-1.0, 1.0);
    bytes.setInt16(headerSize + i * 2, (value * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  Directory(outputDir).createSync(recursive: true);
  sounds.forEach((name, notes) {
    final samples = [for (final note in notes) ...render(note)];
    final file = File('$outputDir/$name.wav')..writeAsBytesSync(wav(samples));
    final kb = (file.lengthSync() / 1024).toStringAsFixed(1);
    stdout.writeln('${file.path}: $kb KB');
  });
}
