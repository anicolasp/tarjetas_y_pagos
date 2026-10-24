import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/banks.dart';
import 'package:tarjetas_y_pagos/core/theme.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/features/reports/chart_colors.dart';

void main() {
  final surfaces = {
    'light': lightTheme.colorScheme.surface,
    'dark': darkTheme.colorScheme.surface,
  };
  final colors = {
    for (final c in baseCategories) c.name: Color(c.color),
    for (final (i, c) in cardColors.indexed) 'card $i': Color(c),
  };

  for (final MapEntry(key: mode, value: surface) in surfaces.entries) {
    test('every category and card color reads on the $mode surface', () {
      for (final MapEntry(key: name, value: color) in colors.entries) {
        final shown = readableOn(color, surface);
        expect(
          contrastRatio(shown, surface),
          greaterThanOrEqualTo(chartMarkContrast),
          reason: '$name on $mode',
        );
      }
    });
  }

  test('a color that already reads is not changed', () {
    const teal = Color(0xFF00897B);
    expect(readableOn(teal, Colors.white), teal);
  });

  test('the hue is kept when adjusting', () {
    const yellow = Color(0xFFF9A825); // too light on a light surface
    final shown = readableOn(yellow, lightTheme.colorScheme.surface);
    expect(shown, isNot(yellow));
    expect(
      HSLColor.fromColor(shown).hue,
      closeTo(HSLColor.fromColor(yellow).hue, 1),
    );
  });
}
