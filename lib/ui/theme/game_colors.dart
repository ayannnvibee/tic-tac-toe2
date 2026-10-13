import 'package:flutter/material.dart';

/// Colours the game needs beyond the Material [ColorScheme]: the board, the
/// two marks, the winning highlight and the chunky call-to-action buttons.
///
/// Light values come from the "Tactile Joy" design system. The design has no
/// dark mode, so the dark values are derived from the same tonal palette.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.card,
    required this.cell,
    required this.boardTray,
    required this.inset,
    required this.xMark,
    required this.oMark,
    required this.xBadge,
    required this.onXBadge,
    required this.oBadge,
    required this.onOBadge,
    required this.xWash,
    required this.oWash,
    required this.winFill,
    required this.winOutline,
    required this.emptyDot,
    required this.ctaStart,
    required this.ctaEnd,
    required this.ctaLip,
    required this.onCta,
    required this.retryStart,
    required this.retryEnd,
    required this.retryLip,
    required this.trophyStart,
    required this.trophyEnd,
    required this.onTrophy,
    required this.scrim,
    required this.shadow,
  });

  /// Raised cards, pills and modal sheets.
  final Color card;

  /// A board cell, empty or marked.
  final Color cell;

  /// The tray the cells sit in.
  final Color boardTray;

  /// Recessed strips inside a card.
  final Color inset;

  /// The human's X and the computer's O as drawn on a [cell].
  final Color xMark;
  final Color oMark;

  /// Solid player badges and the text or icon on them.
  final Color xBadge;
  final Color onXBadge;
  final Color oBadge;
  final Color onOBadge;

  /// Pale tints behind each player's side of the scoreboard.
  final Color xWash;
  final Color oWash;

  /// Cells of the winning line.
  final Color winFill;
  final Color winOutline;

  /// The small dot in an empty cell.
  final Color emptyDot;

  /// Primary purple button: gradient, bottom lip and label.
  final Color ctaStart;
  final Color ctaEnd;
  final Color ctaLip;
  final Color onCta;

  /// The orange "Retry Level" button.
  final Color retryStart;
  final Color retryEnd;
  final Color retryLip;

  /// The trophy badge on the win result.
  final Color trophyStart;
  final Color trophyEnd;
  final Color onTrophy;

  /// The tint behind a result card.
  final Color scrim;

  /// Tint of the soft drop shadows.
  final Color shadow;

  static const GameColors light = GameColors(
    card: Color(0xFFFFFFFF),
    cell: Color(0xFFFFFFFF),
    boardTray: Color(0xFFF5F3EE),
    inset: Color(0xFFF5F3EE),
    xMark: Color(0xFF0058BE),
    oMark: Color(0xFFBC5705),
    xBadge: Color(0xFF2170E4),
    onXBadge: Color(0xFFFEFCFF),
    oBadge: Color(0xFFBC5705),
    onOBadge: Color(0xFFFFFBFF),
    xWash: Color(0x4DD8E2FF),
    oWash: Color(0x4DFFDBC9),
    winFill: Color(0xFFFEF08A),
    winOutline: Color(0xFFFBBF24),
    emptyDot: Color(0x2ECBC3D7),
    ctaStart: Color(0xFF6B38D4),
    ctaEnd: Color(0xFF8455EF),
    ctaLip: Color(0xFF5516BE),
    onCta: Color(0xFFFFFFFF),
    retryStart: Color(0xFFBC5705),
    retryEnd: Color(0xFF974400),
    retryLip: Color(0xFF763300),
    trophyStart: Color(0xFFFFDBC9),
    trophyEnd: Color(0xFFFFB68D),
    onTrophy: Color(0xFF321200),
    scrim: Color(0x592E1065),
    shadow: Color(0xFF8B5CF6),
  );

  static const GameColors dark = GameColors(
    card: Color(0xFF24251F),
    cell: Color(0xFF2C2D27),
    boardTray: Color(0xFF1A1B17),
    inset: Color(0xFF1A1B17),
    xMark: Color(0xFFADC6FF),
    oMark: Color(0xFFFFB68D),
    xBadge: Color(0xFF2170E4),
    onXBadge: Color(0xFFFEFCFF),
    oBadge: Color(0xFFBC5705),
    onOBadge: Color(0xFFFFFBFF),
    xWash: Color(0x40004395),
    oWash: Color(0x40763300),
    winFill: Color(0xFF4A3F0C),
    winOutline: Color(0xFFFBBF24),
    emptyDot: Color(0x33CBC3D7),
    ctaStart: Color(0xFF6B38D4),
    ctaEnd: Color(0xFF8455EF),
    ctaLip: Color(0xFF3F1296),
    onCta: Color(0xFFFFFFFF),
    retryStart: Color(0xFFBC5705),
    retryEnd: Color(0xFF974400),
    retryLip: Color(0xFF5A2700),
    trophyStart: Color(0xFFFFDBC9),
    trophyEnd: Color(0xFFFFB68D),
    onTrophy: Color(0xFF321200),
    scrim: Color(0x99000000),
    shadow: Color(0xFF000000),
  );

  @override
  GameColors copyWith() => this;

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      card: mix(card, other.card),
      cell: mix(cell, other.cell),
      boardTray: mix(boardTray, other.boardTray),
      inset: mix(inset, other.inset),
      xMark: mix(xMark, other.xMark),
      oMark: mix(oMark, other.oMark),
      xBadge: mix(xBadge, other.xBadge),
      onXBadge: mix(onXBadge, other.onXBadge),
      oBadge: mix(oBadge, other.oBadge),
      onOBadge: mix(onOBadge, other.onOBadge),
      xWash: mix(xWash, other.xWash),
      oWash: mix(oWash, other.oWash),
      winFill: mix(winFill, other.winFill),
      winOutline: mix(winOutline, other.winOutline),
      emptyDot: mix(emptyDot, other.emptyDot),
      ctaStart: mix(ctaStart, other.ctaStart),
      ctaEnd: mix(ctaEnd, other.ctaEnd),
      ctaLip: mix(ctaLip, other.ctaLip),
      onCta: mix(onCta, other.onCta),
      retryStart: mix(retryStart, other.retryStart),
      retryEnd: mix(retryEnd, other.retryEnd),
      retryLip: mix(retryLip, other.retryLip),
      trophyStart: mix(trophyStart, other.trophyStart),
      trophyEnd: mix(trophyEnd, other.trophyEnd),
      onTrophy: mix(onTrophy, other.onTrophy),
      scrim: mix(scrim, other.scrim),
      shadow: mix(shadow, other.shadow),
    );
  }
}

extension GameColorsContext on BuildContext {
  GameColors get gameColors => Theme.of(this).extension<GameColors>()!;
}
