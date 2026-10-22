import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/responsive.dart';

import '../helpers/screen_sizes.dart';

void main() {
  test('size classes follow Material 3 breakpoints', () {
    expect(ScreenSize.fromWidth(320), ScreenSize.compact);
    expect(ScreenSize.fromWidth(599.9), ScreenSize.compact);
    expect(ScreenSize.fromWidth(600), ScreenSize.medium);
    expect(ScreenSize.fromWidth(839.9), ScreenSize.medium);
    expect(ScreenSize.fromWidth(840), ScreenSize.expanded);
  });

  testWidgets('ResponsiveCenter caps width on tablets', (tester) async {
    setScreen(tester, const Size(1280, 800), 1);
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveCenter(
          maxWidth: ContentWidth.form,
          child: SizedBox(
            key: ValueKey('content'),
            width: double.infinity,
            height: 10,
          ),
        ),
      ),
    );
    // 480 max width minus 2 * 32 expanded padding.
    expect(tester.getSize(find.byKey(const ValueKey('content'))).width, 416);
  });

  testWidgets('ResponsiveCenter uses compact padding on phones', (
    tester,
  ) async {
    setScreen(tester, const Size(360, 640), 1);
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveCenter(
          child: SizedBox(
            key: ValueKey('content'),
            width: double.infinity,
            height: 10,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('content'))).width, 328);
  });
}
