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

ARCHITECTURE RULES

* domain/ and ai/ are pure Dart with no Flutter imports, fully unit tested.
* State management: Riverpod (Notifier / AsyncNotifier). UI widgets read state and call notifier methods only; no game logic in widgets.
* Every phase must end with `flutter analyze` showing no issues and `flutter test` passing.
