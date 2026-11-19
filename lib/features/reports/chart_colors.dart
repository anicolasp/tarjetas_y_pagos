import 'package:flutter/material.dart';

/// Minimum contrast of a chart mark against its surface (WCAG non-text).
const chartMarkContrast = 3.0;

double contrastRatio(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Minimum contrast of normal-size text against its surface (WCAG AA).
const textContrast = 4.5;

/// [color] (a category's or a card's) made readable on [surface]: the same
/// hue, lightened on a dark surface or darkened on a light one until it
/// reaches [minRatio]. The identity stays, the mark stays visible.
Color readableOn(
  Color color,
  Color surface, {
  double minRatio = chartMarkContrast,
}) {
  if (contrastRatio(color, surface) >= minRatio) return color;
  final darkSurface = surface.computeLuminance() < 0.5;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 25; i++) {
    final l = (hsl.lightness + (darkSurface ? 0.03 : -0.03)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(l);
    if (contrastRatio(hsl.toColor(), surface) >= minRatio) break;
  }
  return hsl.toColor();
}

/// The green of paid amounts, readable as text (AA) on every surface of
/// [scheme], high contrast included.
/// Cached per surface: the app only has a few themes.
Color paidColor(ColorScheme scheme) => _paidColors.putIfAbsent(
  // The darkest surface in light mode, the lightest in dark mode: the
  // worst case for this green on any card or list.
  scheme.surfaceContainerHighest,
  () => readableOn(
    const Color(0xFF2E7D32),
    scheme.surfaceContainerHighest,
    minRatio: textContrast,
  ),
);

final _paidColors = <Color, Color>{};
