import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'game_colors.dart';

/// The "Tactile Joy" design system as Flutter themes.
abstract final class AppTheme {
  /// Bundled in assets/fonts; see pubspec.yaml.
  static const String fontFamily = 'NunitoSans';

  static final ThemeData light = _build(_lightScheme, GameColors.light);
  static final ThemeData dark = _build(_darkScheme, GameColors.dark);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6B38D4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF8455EF),
    onPrimaryContainer: Color(0xFFFFFBFF),
    primaryFixed: Color(0xFFE9DDFF),
    primaryFixedDim: Color(0xFFD0BCFF),
    onPrimaryFixed: Color(0xFF23005C),
    onPrimaryFixedVariant: Color(0xFF5516BE),
    secondary: Color(0xFF0058BE),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF2170E4),
    onSecondaryContainer: Color(0xFFFEFCFF),
    secondaryFixed: Color(0xFFD8E2FF),
    secondaryFixedDim: Color(0xFFADC6FF),
    onSecondaryFixed: Color(0xFF001A42),
    onSecondaryFixedVariant: Color(0xFF004395),
    tertiary: Color(0xFF974400),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFBC5705),
    onTertiaryContainer: Color(0xFFFFFBFF),
    tertiaryFixed: Color(0xFFFFDBC9),
    tertiaryFixedDim: Color(0xFFFFB68D),
    onTertiaryFixed: Color(0xFF321200),
    onTertiaryFixedVariant: Color(0xFF763300),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFBF9F3),
    onSurface: Color(0xFF1B1C19),
    onSurfaceVariant: Color(0xFF494454),
    surfaceDim: Color(0xFFDBDAD4),
    surfaceBright: Color(0xFFFBF9F3),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F3EE),
    surfaceContainer: Color(0xFFF0EEE8),
    surfaceContainerHigh: Color(0xFFEAE8E2),
    surfaceContainerHighest: Color(0xFFE4E2DD),
    outline: Color(0xFF7B7486),
    outlineVariant: Color(0xFFCBC3D7),
    inverseSurface: Color(0xFF30312D),
    onInverseSurface: Color(0xFFF2F1EB),
    inversePrimary: Color(0xFFD0BCFF),
    surfaceTint: Color(0xFF6D3BD7),
  );

  /// Derived from the light palette: the same hues at the tones Material uses
  /// for dark schemes, on the design's warm near-black instead of cream.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF3C0091),
    primaryContainer: Color(0xFF5516BE),
    onPrimaryContainer: Color(0xFFE9DDFF),
    primaryFixed: Color(0xFF3A2470),
    primaryFixedDim: Color(0xFF2C1A57),
    onPrimaryFixed: Color(0xFFE9DDFF),
    onPrimaryFixedVariant: Color(0xFFD0BCFF),
    secondary: Color(0xFFADC6FF),
    onSecondary: Color(0xFF002E69),
    secondaryContainer: Color(0xFF004395),
    onSecondaryContainer: Color(0xFFD8E2FF),
    secondaryFixed: Color(0xFF14315F),
    secondaryFixedDim: Color(0xFF0E2549),
    onSecondaryFixed: Color(0xFFD8E2FF),
    onSecondaryFixedVariant: Color(0xFFADC6FF),
    tertiary: Color(0xFFFFB68D),
    onTertiary: Color(0xFF532200),
    tertiaryContainer: Color(0xFF763300),
    onTertiaryContainer: Color(0xFFFFDBC9),
    tertiaryFixed: Color(0xFF55290A),
    tertiaryFixedDim: Color(0xFF3F1E07),
    onTertiaryFixed: Color(0xFFFFDBC9),
    onTertiaryFixedVariant: Color(0xFFFFB68D),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF131410),
    onSurface: Color(0xFFE4E2DD),
    onSurfaceVariant: Color(0xFFCBC3D7),
    surfaceDim: Color(0xFF131410),
    surfaceBright: Color(0xFF393A35),
    surfaceContainerLowest: Color(0xFF0E0F0C),
    surfaceContainerLow: Color(0xFF1B1C19),
    surfaceContainer: Color(0xFF1F201C),
    surfaceContainerHigh: Color(0xFF2A2B27),
    surfaceContainerHighest: Color(0xFF353631),
    outline: Color(0xFF958EA0),
    outlineVariant: Color(0xFF494454),
    inverseSurface: Color(0xFFE4E2DD),
    onInverseSurface: Color(0xFF30312D),
    inversePrimary: Color(0xFF6B38D4),
    surfaceTint: Color(0xFFD0BCFF),
  );

  static ThemeData _build(ColorScheme scheme, GameColors game) {
    final text = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: fontFamily,
      textTheme: text,
      extensions: [game],
      splashFactory: InkRipple.splashFactory,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(game.card),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? game.ctaStart
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: game.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    );
  }

  /// The design's type scale mapped onto Material's slots.
  ///
  /// | Design token        | Slot           |
  /// | display-hero-mobile | displaySmall   |
  /// | headline-lg-mobile  | headlineLarge  |
  /// | headline-md         | headlineMedium |
  /// | headline-sm         | headlineSmall  |
  /// | score-num           | displayMedium  |
  /// | body-lg / md / sm   | bodyLarge / Medium / Small |
  /// | label-lg / md / sm  | labelLarge / Medium / Small |
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle style(
      double size,
      double height,
      FontWeight weight, {
      double spacingEm = 0,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: spacingEm * size,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return TextTheme(
      displaySmall: style(38, 44, FontWeight.w900, spacingEm: -0.02),
      displayMedium: style(32, 36, FontWeight.w900),
      headlineLarge: style(26, 32, FontWeight.w800, spacingEm: -0.01),
      headlineMedium: style(22, 28, FontWeight.w800),
      headlineSmall: style(18, 24, FontWeight.w800),
      titleLarge: style(22, 28, FontWeight.w800),
      titleMedium: style(18, 24, FontWeight.w800),
      titleSmall: style(15, 20, FontWeight.w800, spacingEm: 0.02),
      bodyLarge: style(18, 26, FontWeight.w600),
      bodyMedium: style(16, 22, FontWeight.w600),
      bodySmall: style(14, 20, FontWeight.w600),
      labelLarge: style(15, 20, FontWeight.w800, spacingEm: 0.02),
      labelMedium: style(13, 18, FontWeight.w800, spacingEm: 0.02),
      labelSmall: style(11, 14, FontWeight.w700, spacingEm: 0.04),
    );
  }
}
