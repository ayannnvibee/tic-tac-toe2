import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';

import 'fixtures.dart';

void main() {
  void expectFreshRound(Session session, int size) {
    expect(session.boardSize, size);
    expect(session.round.board, Board.empty(size));
    expect(session.round.status, RoundStatus.inProgress);
    expect(session.round.currentTurn, Player.human);
    expect(session.round.winningLine, isNull);
    expect(session.round.lastMove, isNull);
  }

  void expectInitial(Session session) {
    expectFreshRound(session, 3);
    expect(session.humanWins, 0);
    expect(session.computerWins, 0);
  }

  test('initial session is 3x3, 0/0, human to move', () {
    expectInitial(Session.initial());
  });

  test('human win grows the board by exactly 1 and only adds a human win', () {
    final next = Session.initial().nextRoundAfter(RoundStatus.humanWon);

    expectFreshRound(next, 4);
    expect(next.humanWins, 1);
    expect(next.computerWins, 0);
  });

  test('computer win keeps the size and only adds a computer win', () {
    final start = Session.initial().nextRoundAfter(RoundStatus.humanWon);
    final next = start.nextRoundAfter(RoundStatus.computerWon);

    expectFreshRound(next, 4);
    expect(next.humanWins, 1);
    expect(next.computerWins, 1);
  });

  test('draw resets to 3x3 with 0/0', () {
    final played = Session.initial()
        .nextRoundAfter(RoundStatus.humanWon)
        .nextRoundAfter(RoundStatus.humanWon)
        .nextRoundAfter(RoundStatus.computerWon);
    expect(played.boardSize, 5);

    expectInitial(played.nextRoundAfter(RoundStatus.draw));
  });

  test('newGame resets to 3x3 with 0/0', () {
    final played = Session.initial()
        .nextRoundAfter(RoundStatus.humanWon)
        .nextRoundAfter(RoundStatus.computerWon);
    final midRound = played.withRound(
      play(played.round, const [Position(0, 0), Position(1, 1)]),
    );

    expectInitial(midRound.newGame());
  });

  test('a round still in progress has no next round', () {
    expect(
      () => Session.initial().nextRoundAfter(RoundStatus.inProgress),
      throwsArgumentError,
    );
  });

  test('3x3 human win, 4x4 computer win, 4x4 human win, 5x5 draw', () {
    var session = Session.initial();
    expectInitial(session);

    session = session.nextRoundAfter(RoundStatus.humanWon);
    expectFreshRound(session, 4);
    expect((session.humanWins, session.computerWins), (1, 0));

    session = session.nextRoundAfter(RoundStatus.computerWon);
    expectFreshRound(session, 4);
    expect((session.humanWins, session.computerWins), (1, 1));

    session = session.nextRoundAfter(RoundStatus.humanWon);
    expectFreshRound(session, 5);
    expect((session.humanWins, session.computerWins), (2, 1));

    session = session.nextRoundAfter(RoundStatus.draw);
    expectInitial(session);
  });

  test('played rounds drive the progression', () {
    var session = Session.initial();

    // Human takes the top row on 3x3.
    session = session.withRound(
      play(session.round, const [
        Position(0, 0),
        Position(1, 0),
        Position(0, 1),
        Position(1, 1),
        Position(0, 2),
      ]),
    );
    expect(session.round.status, RoundStatus.humanWon);
    // Counters and size only change when the next round starts.
    expect((session.boardSize, session.humanWins), (3, 0));

    session = session.nextRoundAfter(session.round.status);
    expectFreshRound(session, 4);
    expect((session.humanWins, session.computerWins), (1, 0));

    // Computer takes the bottom row on 4x4.
    session = session.withRound(
      play(session.round, const [
        Position(0, 0),
        Position(3, 0),
        Position(0, 1),
        Position(3, 1),
        Position(1, 3),
        Position(3, 2),
        Position(2, 0),
        Position(3, 3),
      ]),
    );
    expect(session.round.status, RoundStatus.computerWon);

    session = session.nextRoundAfter(session.round.status);
    expectFreshRound(session, 4);
    expect((session.humanWins, session.computerWins), (1, 1));
  });

  test('withRound rejects a round of a different size', () {
    expect(
      () => Session.initial().withRound(RoundState.initial(4)),
      throwsArgumentError,
    );
  });
}
