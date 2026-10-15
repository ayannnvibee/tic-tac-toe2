# Tic Tac Toe Infinity

Flutter game, Android first (iOS kept for later).

## Commands

- `flutter analyze`
- `flutter test`
- `dart run tool/generate_sounds.dart` regenerates the WAV effects in `assets/sounds/` (synthesized tones, nothing licensed).

## Folder layout

```
lib/
  main.dart
  app.dart        (MaterialApp, theme, routes)
  domain/         (pure Dart game engine, NO Flutter imports)
  ai/             (pure Dart AI, NO Flutter imports)
  state/          (Riverpod providers / notifiers)
  ui/screens/
  ui/widgets/
  ui/theme/
test/
  domain/
  ai/
  state/
  widget/
```

## Spec

PRODUCT RULES (source of truth)

* Single player: Human (X) vs Computer (O). Human moves first in the very first round of a session. Turns alternate. A cell can be marked only once.
* Board starts at 3x3. Win length: 3 on 3x3 and 4x4, 4 on 5x5, 5 on 6x6 and larger (`winLengthFor` in `lib/domain/rules.dart`).
* Wins count consecutive marks horizontally, vertically, and both diagonals, anywhere on the board (not only full rows).
* HUMAN WIN: highlight winning line, show "You Win", humanWins += 1, next round board size += 1 (3x3 -> 4x4 -> 5x5 -> 6x6 ...).
* COMPUTER WIN: highlight winning line, show "Computer Wins", computerWins += 1, next round is a fresh board of the SAME size. Human level never changes on a computer win.
* DRAW (board full, no winner): reset everything to the initial state: 3x3 board, both counters 0.
* NEW GAME button: same full reset as a draw.
* The loser's counter never changes. All marks are cleared before every next round.
* No persistence: every app launch starts at 3x3 with 0/0. No high scores, no history, no saved level.
* After a win or draw, further taps on the board are ignored until the next round starts. Invalid taps (occupied cell, not human's turn) are rejected.
* AI makes exactly one legal move per turn, never out of turn, never on an occupied cell, and must not freeze the UI on large boards.
* Offline only. No ads, no accounts, no backend, no analytics.

FIRST MOVE

* The human moves first in every round, not only the first round of a session. This is the single constant `firstPlayerOfRound` in `lib/domain/rules.dart`; change it there if the opening move should ever alternate.

## Difficulty tuning

All tuning numbers live in `lib/ai/difficulty_tuning.dart`. After changing one, run `flutter test test/ai/balance_test.dart test/ai/win_block_test.dart`, read the printed rates, and update this table.

Medium, by board size:

| Board | Blunder chance | Blunder pool | Line defence |
| --- | --- | --- | --- |
| 3x3 | 25% | best 5 | not used (minimax) |
| 4x4 | 10% | best 3 | 1 |
| 5x5 | 10% | best 3 | 1 |
| 6x6 | 35% | best 3 | 0.05 |
| 7x7 and larger | 20% | best 4 | 0.05 |

* Blunder chance: per move, the chance the computer plays a random one of its best few scored moves instead of the best one. A blunder skips the block and threat rules, so it can miss a block. It still always takes an immediate win.
* Blunder pool: how many of the best scored moves a blunder chooses between.
* Line defence: how eagerly the computer spoils the human's lines before they become an immediate threat (0 never, 1 always). With 3 in a row on 4x4 and 4 in a row on 5x5 the first player can force a win, so the computer plays close to its best there and the human still wins most rounds. From 6x6 up, full line defence drew almost every game, so it is turned down.
* Hard never blunders and always uses line defence 1. Easy wins and blocks, otherwise plays a random nearby cell.

Measured on medium (200 seeded games per size, the simulated human moves first). On 3x3 the simulated human plays perfectly. On 4x4 and larger a flawless player wins every game (the first player can force a win), so the simulated human uses the heuristic engine with a 30% blunder chance (best 4, line defence 0.5) to stand in for a real person.

| Board | Human wins | Draws | Computer wins | Immediate threats blocked |
| --- | --- | --- | --- | --- |
| 3x3 | 38.5% | 61.5% | 0% | not measured |
| 4x4 | 93.5% | 0% | 6.5% | 96.0% |
| 5x5 | 68.5% | 20.5% | 11.0% | 94.3% |
| 6x6 | 40.0% | 53.0% | 7.0% | 77.1% |
| 7x7 | 56.5% | 30.0% | 13.5% | 86.3% |
| 8x8 | 67.0% | 4.5% | 28.5% | not measured |

The tests assert at least 30% human wins on 3x3, 4x4 and 5x5, at least 25% on 6x6 to 8x8, and at least 70% of immediate threats blocked on 4x4 and larger.

ARCHITECTURE RULES

* domain/ and ai/ are pure Dart with no Flutter imports, fully unit tested.
* State management: Riverpod (Notifier / AsyncNotifier). UI widgets read state and call notifier methods only; no game logic in widgets.
* Every phase must end with `flutter analyze` showing no issues and `flutter test` passing.
