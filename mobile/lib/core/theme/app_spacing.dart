/// Consistent spacing for lists, cards, and screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double pageHorizontal = 16;
  static const double pageVertical = 16;
  static const double cardPadding = 16;
  static const double listGap = 12;
  static const double sectionGap = 24;
  static const double cardRadius = 16;
  static const double chipRadius = 24;
  static const double buttonRadius = 14;
  static const double sheetRadius = 24;
  static const double imageRadius = 12;
}

/// Animation duration constants.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration shimmer = Duration(milliseconds: 1500);
}
