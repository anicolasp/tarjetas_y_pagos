import 'package:flutter/material.dart';

/// Brand seed: financial teal.
const brandSeed = Color(0xFF0F766E);

/// The bundled legible font (#38, `assets/fonts/`).
const legibleFontFamily = 'AtkinsonHyperlegible';

/// The app theme. [highContrast] is the same seed at maximum contrast (WCAG
/// AA or better) with solid, outlined fields; [legibleFont] swaps the font
/// for Atkinson Hyperlegible (#38).
ThemeData buildTheme(
  Brightness brightness, {
  bool highContrast = false,
  bool legibleFont = false,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: brightness,
    contrastLevel: highContrast ? 1 : 0,
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: legibleFont ? legibleFontFamily : null,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: highContrast
          ? scheme.surface
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      // High contrast: every field shows its edge (3:1 for components).
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: highContrast
            ? BorderSide(color: scheme.outline)
            : BorderSide.none,
      ),
      enabledBorder: highContrast
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outline),
            )
          : null,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Height only: buttons stretch inside stretched columns but stay
        // compact in dialogs and rows.
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

final lightTheme = buildTheme(Brightness.light);
final darkTheme = buildTheme(Brightness.dark);
