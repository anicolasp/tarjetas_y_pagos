import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Rule #2 for the #3 screens: no overflow on small phones, landscape,
/// tablets and text x2, in light and dark.
void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting(appLocale));
  setUp(() async => db = await openTestDatabase());
  tearDown(() => db.close());

  /// Logged-in user with a long name; [withCards] adds two cards with long
  /// aliases and large limits to stress the layout.
  Future<int?> open(
    WidgetTester tester,
    String location, {
    bool withCards = true,
  }) async {
    final user = await seedUser(db);
    int? cardId;
    if (withCards) {
      cardId = (await seedCard(
        db,
        user.id!,
        alias: 'Gastos del supermercado y la casa',
        cutDay: 5,
        limitCents: 123456789,
      )).id;
      await seedCard(db, user.id!, alias: 'Viajes', cutDay: 25);
    }
    final store = InMemorySecureStore()
      ..values['session_user_id'] = '${user.id}';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: DateTime(2026, 10, 22, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (location != '/home') {
      final context = tester.element(find.byType(Navigator).first);
      GoRouter.of(context).push(location.replaceAll(':id', '$cardId'));
      await tester.pumpAndSettle();
    }
    return cardId;
  }

  final screens = <String, ({String location, bool withCards, String root})>{
    'home without cards': (
      location: '/home',
      withCards: false,
      root: 'home.root',
    ),
    'home with cards': (location: '/home', withCards: true, root: 'home.root'),
    'cards empty': (
      location: '/home/cards',
      withCards: false,
      root: 'cards.empty',
    ),
    'cards list': (
      location: '/home/cards',
      withCards: true,
      root: 'cards.root',
    ),
    'new card form': (
      location: '/home/cards/new',
      withCards: false,
      root: 'cardForm.root',
    ),
    'edit card form': (
      location: '/home/cards/:id/edit',
      withCards: true,
      root: 'cardForm.archive',
    ),
    'card detail': (
      location: '/home/cards/:id',
      withCards: true,
      root: 'cardDetail.empty',
    ),
    'profile': (
      location: '/home/profile',
      withCards: false,
      root: 'profile.root',
    ),
  };

  for (final MapEntry(key: name, value: s) in screens.entries) {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('$name: ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          await open(tester, s.location, withCards: s.withCards);

          // Overflow errors fail the test through tester.takeException.
          expect(tester.takeException(), isNull);
          expect(find.byKey(ValueKey(s.root)), findsOneWidget);
        });
      }
    }
  }
}
