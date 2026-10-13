# Tic Tac Toe Infinity

Flutter game, Android first (iOS kept for later).

## Commands

- `flutter analyze`
- `flutter test`

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
* Board starts at 3x3. Win length = min(boardSize, 5): 3 on 3x3, 4 on 4x4, 5 on 5x5 and larger.
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
| 4x4 | 35% | best 3 | 0.05 |
| 5x5 | 20% | best 4 | 0 |
| 6x6 | 20% | best 4 | 0.05 |
| 7x7 and larger | 20% | best 4 | 1 |

* Blunder chance: per move, the chance the computer plays a random one of its best few scored moves instead of the best one. A blunder skips the block and threat rules, so it can miss a block. It still always takes an immediate win.
* Blunder pool: how many of the best scored moves a blunder chooses between.
* Line defence: how eagerly the computer spoils the human's lines before they become an immediate threat (0 never, 1 always). On 4x4 to 6x6 every line is about as long as the win length, so one computer mark kills a line for good. With line defence at 1 the simulated human won 0% of games on 5x5 at any blunder chance, so it is turned down there. Immediate threats are still blocked unless the move is a blunder.
* Hard never blunders and always uses line defence 1. Easy wins and blocks, otherwise plays a random nearby cell.

Measured on medium (200 seeded games per size, the simulated human moves first and plays the hard engine with no blunders):

| Board | Human wins | Draws | Computer wins | Immediate threats blocked |
| --- | --- | --- | --- | --- |
| 3x3 | 38.5% | 61.5% | 0% | not measured |
| 4x4 | 22.0% | 78.0% | 0% | 78.5% |
| 5x5 | 27.0% | 73.0% | 0% | 86.3% |
| 6x6 | 28.0% | 72.0% | 0% | 85.2% |
| 7x7 | 26.5% | 73.5% | 0% | 86.3% |
| 8x8 | 51.5% | 48.5% | 0% | not measured |

The tests assert at least 30% human wins on 3x3, at least 15% on 4x4, 5x5 and 6x6, and at least 70% of immediate threats blocked on 4x4 and larger.

ARCHITECTURE RULES

* domain/ and ai/ are pure Dart with no Flutter imports, fully unit tested.
* State management: Riverpod (Notifier / AsyncNotifier). UI widgets read state and call notifier methods only; no game logic in widgets.
* Every phase must end with `flutter analyze` showing no issues and `flutter test` passing.
