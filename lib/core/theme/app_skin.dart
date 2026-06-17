import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Identifies which theme pack drives the live look. `noir` is the free
/// default; the rest map to paid `category: 'theme'` bundle slugs.
enum SkinId { noir, cyberpunk, victorian, wildWest }

/// The full-screen backdrop treatment a skin paints behind every page.
enum SkinTexture { grain, scanlines, parchment, kraft, fog, grid }

/// The bespoke in-game countdown treatment a skin uses.
enum SkinTimerStyle { ring, digital, flipClock, pocketWatch }

/// The bespoke framing the role-reveal card uses.
enum SkinRoleCardStyle { plain, hud, wantedPoster, callingCard }

/// A complete visual identity for the app — palette, card geometry, fonts,
/// and background texture. Carried as a [ThemeExtension] inside the active
/// [ThemeData] so Material components and bespoke widgets read from one
/// source of truth, and so switching skins cross-fades for free.
///
/// `noir` is backed by [AppColors] so the default look stays defined in one
/// place. Other skins are authored below with their own palettes.
@immutable
class AppSkin extends ThemeExtension<AppSkin> {
  const AppSkin({
    required this.id,
    required this.ink,
    required this.inkRaised,
    required this.inkSurface,
    required this.inkOutline,
    required this.paper,
    required this.paperMuted,
    required this.paperFaint,
    required this.accent,
    required this.accentMuted,
    required this.secondary,
    required this.danger,
    required this.success,
    required this.cardRadius,
    required this.cardBorderWidth,
    required this.cardGlow,
    required this.buttonRadius,
    required this.inputRadius,
    required this.texture,
    required this.displayFontFamily,
    required this.bodyFontFamily,
    required this.monoFontFamily,
    required this.displayIsSerif,
    required this.timerStyle,
    required this.roleCardStyle,
    required this.digitFontFamily,
    required this.ornament,
  });

  final SkinId id;

  // Surfaces (dark→raised) and outlines.
  final Color ink;
  final Color inkRaised;
  final Color inkSurface;
  final Color inkOutline;

  // Foreground ink-on-paper hierarchy.
  final Color paper;
  final Color paperMuted;
  final Color paperFaint;

  // Accents.
  final Color accent;
  final Color accentMuted;
  final Color secondary;
  final Color danger;
  final Color success;

  // Geometry.
  final double cardRadius;
  final double cardBorderWidth;
  final bool cardGlow;
  final double buttonRadius;
  final double inputRadius;

  // Backdrop + type.
  final SkinTexture texture;
  final String displayFontFamily;
  final String bodyFontFamily;
  final String monoFontFamily;
  final bool displayIsSerif;

  // Bespoke component treatments + the legible face used for ALL large
  // numerals (kept separate from the decorative display font so digits stay
  // readable). `ornament` is a single "fancy chrome on/off" lever for
  // bezels, filigree, poster nails, etc.
  final SkinTimerStyle timerStyle;
  final SkinRoleCardStyle roleCardStyle;
  final String digitFontFamily;
  final bool ornament;

  /// Monospace/typewriter style helper (replaces the old
  /// `AppTypography.mono`). Resolves the skin's [monoFontFamily] at runtime.
  TextStyle monoStyle({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    Color? color,
  }) {
    return GoogleFonts.getFont(monoFontFamily).copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? paper,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Style for large numerals (timer digits, 3-2-1 countdown, flip cards).
  /// Resolves [digitFontFamily] — always a legible face, never the
  /// decorative display font — with tabular figures so digits don't jitter.
  TextStyle digitStyle({
    double size = 48,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 0,
    Color? color,
  }) {
    return GoogleFonts.getFont(digitFontFamily).copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? paper,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static AppSkin byId(SkinId id) => switch (id) {
        SkinId.noir => noir,
        SkinId.cyberpunk => cyberpunk,
        SkinId.victorian => victorian,
        SkinId.wildWest => wildWest,
      };

  /// Default free look — sources its palette from [AppColors] so the
  /// canonical noir/spy identity is defined once.
  static const AppSkin noir = AppSkin(
    id: SkinId.noir,
    ink: AppColors.ink,
    inkRaised: AppColors.inkRaised,
    inkSurface: AppColors.inkSurface,
    inkOutline: AppColors.inkOutline,
    paper: AppColors.paper,
    paperMuted: AppColors.paperMuted,
    paperFaint: AppColors.paperFaint,
    accent: AppColors.lime,
    accentMuted: AppColors.limeMuted,
    secondary: AppColors.amber,
    danger: AppColors.signalRed,
    success: AppColors.success,
    cardRadius: 24,
    cardBorderWidth: 1.5,
    cardGlow: false,
    buttonRadius: 18,
    inputRadius: 16,
    texture: SkinTexture.grain,
    displayFontFamily: 'Space Grotesk',
    bodyFontFamily: 'Space Grotesk',
    monoFontFamily: 'JetBrains Mono',
    displayIsSerif: false,
    timerStyle: SkinTimerStyle.ring,
    roleCardStyle: SkinRoleCardStyle.plain,
    digitFontFamily: 'JetBrains Mono',
    ornament: false,
  );

  /// Neon-and-chrome night city. Square cards, glowing borders, scanlines.
  static const AppSkin cyberpunk = AppSkin(
    id: SkinId.cyberpunk,
    ink: Color(0xFF07060F),
    inkRaised: Color(0xFF120B23),
    inkSurface: Color(0xFF1B1136),
    inkOutline: Color(0xFF3A2E63),
    paper: Color(0xFFECE6FF),
    paperMuted: Color(0xFFA99FD6),
    paperFaint: Color(0xFF6E6597),
    accent: Color(0xFF00F0FF),
    accentMuted: Color(0xFF14B8C4),
    secondary: Color(0xFFFF2E97),
    danger: Color(0xFFFF3864),
    success: Color(0xFF39FF14),
    cardRadius: 8,
    cardBorderWidth: 1.5,
    cardGlow: true,
    buttonRadius: 6,
    inputRadius: 6,
    texture: SkinTexture.grid,
    displayFontFamily: 'Chakra Petch',
    bodyFontFamily: 'Chakra Petch',
    monoFontFamily: 'Share Tech Mono',
    displayIsSerif: false,
    timerStyle: SkinTimerStyle.digital,
    roleCardStyle: SkinRoleCardStyle.hud,
    digitFontFamily: 'Share Tech Mono',
    ornament: true,
  );

  /// Cool gaslit London at night: teal-navy fog, ivory paper, brass/gold and
  /// oxblood. Engraved Cinzel capitals, ornate pocket-watch + calling-card.
  /// Deliberately cool/refined to contrast the warm/rugged [wildWest].
  static const AppSkin victorian = AppSkin(
    id: SkinId.victorian,
    ink: Color(0xFF0E1418),
    inkRaised: Color(0xFF15202A),
    inkSurface: Color(0xFF1C2A35),
    inkOutline: Color(0xFF31485A),
    paper: Color(0xFFECE6D6),
    paperMuted: Color(0xFFB7B09C),
    paperFaint: Color(0xFF7C8590),
    accent: Color(0xFFC9A24B),
    accentMuted: Color(0xFF8C7636),
    secondary: Color(0xFF7E2B2B),
    danger: Color(0xFF9E3B33),
    success: Color(0xFF5E7D5A),
    cardRadius: 4,
    cardBorderWidth: 1.0,
    cardGlow: false,
    buttonRadius: 4,
    inputRadius: 4,
    texture: SkinTexture.fog,
    displayFontFamily: 'Cinzel',
    bodyFontFamily: 'EB Garamond',
    monoFontFamily: 'EB Garamond',
    displayIsSerif: true,
    timerStyle: SkinTimerStyle.pocketWatch,
    roleCardStyle: SkinRoleCardStyle.callingCard,
    digitFontFamily: 'EB Garamond',
    ornament: true,
  );

  /// Dusty frontier: soot-brown, kraft cream, burnt leather and rust.
  /// Heavy borders, wanted-poster slab type.
  static const AppSkin wildWest = AppSkin(
    id: SkinId.wildWest,
    ink: Color(0xFF1A1308),
    inkRaised: Color(0xFF271C0E),
    inkSurface: Color(0xFF332514),
    inkOutline: Color(0xFF503B20),
    paper: Color(0xFFF0E2C4),
    paperMuted: Color(0xFFC2A878),
    paperFaint: Color(0xFF8A7245),
    accent: Color(0xFFC8761F),
    accentMuted: Color(0xFF8F5415),
    secondary: Color(0xFF9C3B23),
    danger: Color(0xFFA8321F),
    success: Color(0xFF7C7B2E),
    cardRadius: 2,
    cardBorderWidth: 2.0,
    cardGlow: false,
    buttonRadius: 4,
    inputRadius: 4,
    texture: SkinTexture.kraft,
    displayFontFamily: 'Rye',
    bodyFontFamily: 'Zilla Slab',
    monoFontFamily: 'Special Elite',
    displayIsSerif: true,
    timerStyle: SkinTimerStyle.flipClock,
    roleCardStyle: SkinRoleCardStyle.wantedPoster,
    digitFontFamily: 'Special Elite',
    ornament: true,
  );

  @override
  AppSkin copyWith({
    SkinId? id,
    Color? ink,
    Color? inkRaised,
    Color? inkSurface,
    Color? inkOutline,
    Color? paper,
    Color? paperMuted,
    Color? paperFaint,
    Color? accent,
    Color? accentMuted,
    Color? secondary,
    Color? danger,
    Color? success,
    double? cardRadius,
    double? cardBorderWidth,
    bool? cardGlow,
    double? buttonRadius,
    double? inputRadius,
    SkinTexture? texture,
    String? displayFontFamily,
    String? bodyFontFamily,
    String? monoFontFamily,
    bool? displayIsSerif,
    SkinTimerStyle? timerStyle,
    SkinRoleCardStyle? roleCardStyle,
    String? digitFontFamily,
    bool? ornament,
  }) {
    return AppSkin(
      id: id ?? this.id,
      ink: ink ?? this.ink,
      inkRaised: inkRaised ?? this.inkRaised,
      inkSurface: inkSurface ?? this.inkSurface,
      inkOutline: inkOutline ?? this.inkOutline,
      paper: paper ?? this.paper,
      paperMuted: paperMuted ?? this.paperMuted,
      paperFaint: paperFaint ?? this.paperFaint,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      secondary: secondary ?? this.secondary,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      cardRadius: cardRadius ?? this.cardRadius,
      cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
      cardGlow: cardGlow ?? this.cardGlow,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      texture: texture ?? this.texture,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      displayIsSerif: displayIsSerif ?? this.displayIsSerif,
      timerStyle: timerStyle ?? this.timerStyle,
      roleCardStyle: roleCardStyle ?? this.roleCardStyle,
      digitFontFamily: digitFontFamily ?? this.digitFontFamily,
      ornament: ornament ?? this.ornament,
    );
  }

  @override
  AppSkin lerp(ThemeExtension<AppSkin>? other, double t) {
    if (other is! AppSkin) return this;
    // Colors and geometry interpolate for a smooth crossfade; identity,
    // texture, fonts and bools are not interpolable so they snap at the
    // midpoint.
    final snap = t < 0.5 ? this : other;
    return AppSkin(
      id: snap.id,
      ink: Color.lerp(ink, other.ink, t)!,
      inkRaised: Color.lerp(inkRaised, other.inkRaised, t)!,
      inkSurface: Color.lerp(inkSurface, other.inkSurface, t)!,
      inkOutline: Color.lerp(inkOutline, other.inkOutline, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperMuted: Color.lerp(paperMuted, other.paperMuted, t)!,
      paperFaint: Color.lerp(paperFaint, other.paperFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      cardBorderWidth: lerpDouble(cardBorderWidth, other.cardBorderWidth, t)!,
      cardGlow: snap.cardGlow,
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t)!,
      inputRadius: lerpDouble(inputRadius, other.inputRadius, t)!,
      texture: snap.texture,
      displayFontFamily: snap.displayFontFamily,
      bodyFontFamily: snap.bodyFontFamily,
      monoFontFamily: snap.monoFontFamily,
      displayIsSerif: snap.displayIsSerif,
      timerStyle: snap.timerStyle,
      roleCardStyle: snap.roleCardStyle,
      digitFontFamily: snap.digitFontFamily,
      ornament: snap.ornament,
    );
  }
}
