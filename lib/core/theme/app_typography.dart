import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_skin.dart';

/// Builds the app text theme for a given [AppSkin]. Display/headline/title
/// styles use the skin's display family (decorative on themed skins); body
/// and label styles use the more readable body family. Serif display skins
/// (Victorian, Wild West) get gentler tracking so big serifs don't crowd.
class AppTypography {
  AppTypography._();

  static TextTheme build(AppSkin skin) {
    final display = GoogleFonts.getTextTheme(skin.displayFontFamily);
    final body = GoogleFonts.getTextTheme(skin.bodyFontFamily);
    final serif = skin.displayIsSerif;

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: serif ? FontWeight.w600 : FontWeight.w700,
        letterSpacing: serif ? -0.5 : -1.5,
        height: 1.0,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: serif ? FontWeight.w600 : FontWeight.w700,
        letterSpacing: serif ? -0.3 : -1.0,
        height: 1.05,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: serif ? FontWeight.w600 : FontWeight.w700,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: serif ? 0 : -0.5,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: body.labelMedium,
      labelSmall: body.labelSmall,
      bodyLarge: body.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.5),
      bodySmall: body.bodySmall?.copyWith(height: 1.5),
    ).apply(bodyColor: skin.paper, displayColor: skin.paper);
  }

  /// Backwards-compatible monospace helper. Prefer `context.skin.monoStyle`
  /// in widgets so the family follows the active skin; this static form is
  /// kept for call sites without a [BuildContext] and defaults to the noir
  /// (JetBrains Mono) family.
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
        color: color ?? AppSkin.noir.paper,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.0,
      );
}
