import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_skin.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // Built ThemeData is reused per skin so flipping themes (or unrelated
  // room ticks) doesn't rebuild the (non-trivial) ColorScheme every time.
  static final Map<SkinId, ThemeData> _cache = {};

  /// Convenience for the default look (used before any room is joined).
  static ThemeData dark() => fromSkin(AppSkin.noir);

  static ThemeData fromSkin(AppSkin skin) =>
      _cache.putIfAbsent(skin.id, () => _build(skin));

  static ThemeData _build(AppSkin skin) {
    final scheme = ColorScheme.fromSeed(
      seedColor: skin.accent,
      brightness: Brightness.dark,
      primary: skin.accent,
      onPrimary: skin.ink,
      secondary: skin.secondary,
      surface: skin.inkRaised,
      onSurface: skin.paper,
      error: skin.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[skin],
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      scaffoldBackgroundColor: skin.ink,
      canvasColor: skin.ink,
      textTheme: AppTypography.build(skin),
      iconTheme: IconThemeData(color: skin.paper),
      appBarTheme: AppBarTheme(
        backgroundColor: skin.ink,
        surfaceTintColor: skin.ink,
        foregroundColor: skin.paper,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: skin.inkRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: skin.paperFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.inkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.inkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          backgroundColor: skin.accent,
          foregroundColor: skin.ink,
          disabledBackgroundColor: skin.inkOutline,
          disabledForegroundColor: skin.paperFaint,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          foregroundColor: skin.paper,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: skin.inkOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.buttonRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          foregroundColor: skin.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: skin.inkOutline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: skin.inkSurface,
        contentTextStyle: TextStyle(color: skin.paper),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: skin.inkRaised,
        surfaceTintColor: skin.inkRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(skin.cardRadius),
          side: BorderSide(color: skin.inkOutline),
        ),
      ),
    );
  }
}
