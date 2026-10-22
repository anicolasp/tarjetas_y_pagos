import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/providers.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';

void main() {
  testWidgets('shows the splash while the database opens', (tester) async {
    final overrides = await testOverrides(
      database: Completer<AppDatabase>().future,
    );
    await tester.pumpWidget(testApp(overrides));

    expect(find.byKey(const ValueKey('splash.root')), findsOneWidget);
    expect(find.text('Tarjetas y Pagos'), findsOneWidget);
    expect(find.byKey(const ValueKey('splash.loading')), findsOneWidget);
  });

  testWidgets('shows an error if the database cannot open', (tester) async {
    final overrides = [
      ...await testOverrides(),
      appDatabaseProvider.overrideWith((ref) => Future.error('boom')),
    ];
    await tester.pumpWidget(testApp(overrides));
    await tester.pump();

    expect(find.byKey(const ValueKey('splash.error')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash.retry')), findsOneWidget);
  });

  testWidgets('retry reopens the database', (tester) async {
    var attempts = 0;
    final pending = Completer<AppDatabase>();
    final overrides = [
      ...await testOverrides(),
      appDatabaseProvider.overrideWith((ref) {
        attempts++;
        return attempts == 1 ? Future.error('boom') : pending.future;
      }),
    ];
    await tester.pumpWidget(testApp(overrides));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('splash.retry')));
    await tester.pump();

    expect(attempts, 2);
    expect(find.byKey(const ValueKey('splash.loading')), findsOneWidget);
  });

  for (final c in responsiveCases) {
    for (final brightness in Brightness.values) {
      testWidgets('renders without overflow: ${c.name}, ${brightness.name}', (
        tester,
      ) async {
        setScreen(tester, c.size, c.textScale);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        final overrides = await testOverrides(
          database: Completer<AppDatabase>().future,
        );
        await tester.pumpWidget(testApp(overrides));

        // Overflow errors fail the test through tester.takeException.
        expect(tester.takeException(), isNull);
        expect(find.text('Tarjetas y Pagos'), findsOneWidget);
      });
    }
  }
}
