import 'package:flutter/cupertino.dart';

class AppTheme {
  // Backgrounds
  // The absolute background must be iOS System Gray 6 (#F2F2F7).
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // Interactive cards and active surfaces must be Pure Ceramic White (#FFFFFF).
  static const Color pureCeramicWhite = Color(0xFFFFFFFF);

  // Text should be high-contrast iOS System Black (#1C1C1E).
  static const Color systemBlack = Color(0xFF1C1C1E);

  // Subtle System Gray (#8E8E93) for secondary labels.
  static const Color systemGray = Color(0xFF8E8E93);

  // Accent Colors
  // "Focus Blue" (#007AFF) exclusively for the main '+' FAB / active elements.
  static const Color focusBlue = Color(0xFF007AFF);

  // "Growth Green" (#34C759) for positive financial metrics/active running timer.
  static const Color growthGreen = Color(0xFF34C759);

  // Three States of Matter
  static const Color stateGrowth = Color(0xFF34C759); // Green
  static const Color stateMaintenance = Color(0xFF8E8E93); // Grey
  static const Color stateEntropy = Color(0xFFFF9500); // Orange
  static const Color systemOrange = Color(0xFFFF9500);

  // System Red (#FF3B30) for negative balances.
  static const Color systemRed = Color(0xFFFF3B30);

  // Soft Shadows (rgba(0,0,0,0.05) with a large blur radius)
  static final BoxShadow softShadow = BoxShadow(
    color: const Color(0xFF000000).withOpacity(0.05),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  // Squircle Radius
  static const double squircleRadius = 24.0;
  static final BorderRadius squircleBorderRadius =
      BorderRadius.circular(squircleRadius);

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: focusBlue,
    scaffoldBackgroundColor: systemGray6,
    textTheme: CupertinoTextThemeData(
      primaryColor: systemBlack,
      textStyle: TextStyle(
        fontFamily:
            '.SF Pro Text', // Native system font on iOS, roboto fallback
        color: systemBlack,
        fontSize: 17,
        letterSpacing: -0.41,
      ),
    ),
  );
}
