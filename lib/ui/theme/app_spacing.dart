/// Spacing scale of the design system, in logical pixels.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double gutterSm = 12;
  static const double md = 16;
  static const double margin = 20;
  static const double lg = 24;
  static const double xl = 32;

  /// Side margin of every screen on a phone.
  static const double screenMargin = md;

  /// Content never grows wider than this, so tablets keep a phone layout.
  static const double maxContentWidth = 480;
}

/// Corner radii of the design system, in logical pixels.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 32;
  static const double xl = 48;
  static const double pill = 999;
}
