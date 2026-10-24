import 'package:flutter/material.dart';

/// Minimum contrast of a chart mark against its surface (WCAG non-text).
const chartMarkContrast = 3.0;

double contrastRatio(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// [color] (a category's or a card's) made readable on [surface]: the same
/// hue, lightened on a dark surface or darkened on a light one until it
/// reaches [chartMarkContrast]. The identity stays, the mark stays visible.
Color readableOn(Color color, Color surface) {
  if (contrastRatio(color, surface) >= chartMarkContrast) return color;
  final darkSurface = surface.computeLuminance() < 0.5;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 25; i++) {
    final l = (hsl.lightness + (darkSurface ? 0.03 : -0.03)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(l);
    if (contrastRatio(hsl.toColor(), surface) >= chartMarkContrast) break;
  }
  return hsl.toColor();
}
