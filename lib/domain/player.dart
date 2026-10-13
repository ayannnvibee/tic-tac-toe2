/// The two sides of a round.
enum Player { human, computer }

/// The content of a single board cell.
enum Mark { empty, x, o }

extension PlayerMark on Player {
  /// The mark this player places: human is X, computer is O.
  Mark get mark => switch (this) {
    Player.human => Mark.x,
    Player.computer => Mark.o,
  };

  Player get opponent => switch (this) {
    Player.human => Player.computer,
    Player.computer => Player.human,
  };
}
