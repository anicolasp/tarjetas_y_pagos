import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen configurations every screen must render without overflow
/// (rule #2: responsive app).
const responsiveCases = <({String name, Size size, double textScale})>[
  (name: 'small phone', size: Size(320, 568), textScale: 1),
  (name: 'phone', size: Size(412, 915), textScale: 1),
  (name: 'phone landscape', size: Size(915, 412), textScale: 1),
  (name: 'small landscape', size: Size(568, 320), textScale: 1),
  (name: 'tablet', size: Size(1280, 800), textScale: 1),
  (name: 'phone, text x2', size: Size(360, 640), textScale: 2),
];

/// Sets the logical screen size and text scale for the rest of the test.
void setScreen(WidgetTester tester, Size size, double textScale) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
