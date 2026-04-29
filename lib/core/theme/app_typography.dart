import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Display: Space Grotesk for body/UI; JetBrains Mono for the room code and
/// any numeric/time digits (tabular figures by default).
class AppTypography {
  AppTypography._();

  static TextTheme build() {
    final base = GoogleFonts.spaceGroteskTextTheme();
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            height: 1.0,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
            height: 1.05,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
        )
        .apply(bodyColor: AppColors.paper, displayColor: AppColors.paper);
  }

  static TextStyle mono({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.paper,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.0,
      );
}
