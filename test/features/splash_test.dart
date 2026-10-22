import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/app.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/providers.dart';

import '../helpers/screen_sizes.dart';

void main() {
  testWidgets('shows the splash while the database opens', (tester) async {
    final pending = Completer<AppDatabase>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => pending.future)],
        child: const TarjetasApp(),
      ),
    );

    expect(find.byKey(const ValueKey('splash.root')), findsOneWidget);
    expect(find.text('Tarjetas y Pagos'), findsOneWidget);
    expect(find.byKey(const ValueKey('splash.loading')), findsOneWidget);
  });

  testWidgets('shows an error if the database cannot open', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => Future.error('boom')),
        ],
        child: const TarjetasApp(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('splash.error')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash.retry')), findsOneWidget);
  });

  testWidgets('retry reopens the database', (tester) async {
    var attempts = 0;
    final pending = Completer<AppDatabase>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            attempts++;
            return attempts == 1 ? Future.error('boom') : pending.future;
          }),
        ],
        child: const TarjetasApp(),
      ),
    );
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWith(
                (ref) => Completer<AppDatabase>().future,
              ),
            ],
            child: const TarjetasApp(),
          ),
        );

        // Overflow errors fail the test through tester.takeException.
        expect(tester.takeException(), isNull);
        expect(find.text('Tarjetas y Pagos'), findsOneWidget);
      });
    }
  }
}
