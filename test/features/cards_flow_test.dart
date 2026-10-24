import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/clock.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/features/cards/cards_providers.dart';

import '../helpers/fakes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Home + "Mis tarjetas" through the real app with an in-memory database.
/// "Today" is fixed to Thursday 22 Oct 2026, 10:00.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late int userId;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(WidgetTester tester, {DateTime? now}) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: now ?? today,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  Future<void> fillCard(
    WidgetTester tester, {
    required String alias,
    required String last4,
    required String cutDay,
    String? limit,
  }) async {
    await tester.enterText(key('cardForm.alias'), alias);
    await tester.enterText(key('cardForm.bank'), 'Banco Prueba');
    await tester.enterText(key('cardForm.last4'), last4);
    await tester.enterText(key('cardForm.cutDay'), cutDay);
    if (limit != null) {
      await tester.ensureVisible(key('cardForm.limit'));
      await tester.enterText(key('cardForm.limit'), limit);
    }
    await tapVisible(tester, 'cardForm.save');
  }

  group('home header', () {
    testWidgets('greets by time of day with the user initials', (tester) async {
      await start(tester);
      expect(find.text('Buenos días, María José'), findsOneWidget);
      expect(
        find.descendant(of: key('home.avatar'), matching: find.text('MP')),
        findsOneWidget,
      );
    });

    testWidgets('afternoon and night greetings', (tester) async {
      await start(tester, now: DateTime(2026, 10, 22, 12));
      expect(find.text('Buenas tardes, María José'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await start(tester, now: DateTime(2026, 10, 22, 19));
      expect(find.text('Buenas noches, María José'), findsOneWidget);
    });

    testWidgets('avatar opens the profile, which logs out', (tester) async {
      await start(tester);
      await tester.tap(key('home.avatar'));
      await tester.pumpAndSettle();
      expect(key('profile.root'), findsOneWidget);
      expect(find.text('maria.jose@example.com'), findsOneWidget);
      await tester.tap(key('profile.logout'));
      await tester.pumpAndSettle();
      expect(key('login.root'), findsOneWidget);
    });
  });

  testWidgets('without cards, home invites to add one', (tester) async {
    await start(tester);
    expect(
      find.text('Agrega una tarjeta para saber cuál te conviene usar hoy.'),
      findsOneWidget,
    );
    expect(key('home.carouselEmpty'), findsOneWidget);
    expect(find.text('RD\$ 0.00'), findsNWidgets(2));
  });

  testWidgets('every quick access opens its screen', (tester) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.debts');
    expect(key('debts.root'), findsOneWidget);
  });

  testWidgets('add two cards, best card, edit limit and archive', (
    tester,
  ) async {
    await start(tester);

    // Empty "Mis tarjetas" → add A (cut 5) and B (cut 25).
    await tapVisible(tester, 'home.quick.cards');
    expect(key('cards.empty'), findsOneWidget);
    await tester.tap(key('cards.emptyAdd'));
    await tester.pumpAndSettle();
    await fillCard(tester, alias: 'A', last4: '1111', cutDay: '5');
    expect(find.text('•••• 1111'), findsOneWidget);

    await tester.tap(key('cards.add'));
    await tester.pumpAndSettle();
    await fillCard(tester, alias: 'B', last4: '2222', cutDay: '25');
    expect(find.text('•••• 1111'), findsOneWidget);
    expect(find.text('•••• 2222'), findsOneWidget);

    // Home: both in the carousel; A gives more days (34 vs 23).
    // Android back button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(key('home.root'), findsOneWidget);
    expect(
      find.descendant(
        of: key('home.carousel'),
        matching: find.text('•••• 2222'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('home.rank.0'),
        matching: find.textContaining('A'),
      ),
      findsWidgets,
    );
    expect(
      find.text('Corta en 14 días · pagas el 25/nov · 34 días'),
      findsOneWidget,
    );
    expect(
      find.text('Corta en 3 días · pagas el 14/nov · 23 días'),
      findsOneWidget,
    );

    // Edit A's limit → shown in the list.
    await tapVisible(tester, 'home.seeAllCards');
    final cardA = (await db.db.query('cards', where: "alias = 'A'")).single;
    await tester.tap(key('cards.item.${cardA['id']}'));
    await tester.pumpAndSettle();
    expect(find.text('Editar tarjeta'), findsOneWidget);
    await tester.ensureVisible(key('cardForm.limit'));
    await tester.enterText(key('cardForm.limit'), '50000');
    await tapVisible(tester, 'cardForm.save');
    expect(find.text('Disponible RD\$ 50,000.00'), findsOneWidget);

    // Archive A → only B is left.
    await tester.tap(key('cards.item.${cardA['id']}'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'cardForm.archive');
    await tester.tap(key('cardForm.archiveConfirm'));
    await tester.pumpAndSettle();
    expect(key('cards.root'), findsOneWidget);
    expect(find.text('•••• 1111'), findsNothing);
    expect(find.text('•••• 2222'), findsOneWidget);

    // Home is still below: Android back returns to it instead of closing
    // the app.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('carousel opens the card movements', (tester) async {
    final card = await seedCard(db, userId, alias: 'Viajes', cutDay: 10);
    await start(tester);
    await tapVisible(tester, 'home.carousel.${card.id}');
    expect(key('cardDetail.root'), findsOneWidget);
    expect(find.text('Viajes'), findsWidgets);
    expect(key('cardDetail.empty'), findsOneWidget);
    expect(find.text('Aún no hay movimientos en esta tarjeta'), findsOneWidget);
    // Cut 10 → next cut Nov 10, due Nov 30.
    expect(find.text('10 nov 2026'), findsOneWidget);
    expect(find.text('30 nov 2026'), findsOneWidget);
  });

  testWidgets('form validates every field', (tester) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.cards');
    await tester.tap(key('cards.emptyAdd'));
    await tester.pumpAndSettle();
    await tester.enterText(key('cardForm.last4'), '12');
    await tester.enterText(key('cardForm.cutDay'), '32');
    await tester.ensureVisible(key('cardForm.limit'));
    await tester.enterText(key('cardForm.limit'), 'mucho');
    await tapVisible(tester, 'cardForm.save');

    expect(find.text('Escribe un nombre para la tarjeta'), findsOneWidget);
    expect(find.text('Escribe el banco'), findsOneWidget);
    expect(find.text('Escribe los últimos 4 dígitos'), findsOneWidget);
    expect(find.text('Escribe un día del 1 al 31'), findsOneWidget);
    expect(
      find.text('Monto no válido (ej. 50000 o 50,000.00)'),
      findsOneWidget,
    );
    expect(await db.db.query('cards'), isEmpty);
  });

  testWidgets('last 4 field only accepts 4 digits', (tester) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.cards');
    await tester.tap(key('cards.emptyAdd'));
    await tester.pumpAndSettle();
    await tester.enterText(key('cardForm.last4'), '4111 1111 1111 1111');
    await tester.pump();
    final field = tester.widget<EditableText>(
      find.descendant(
        of: key('cardForm.last4'),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.controller.text, '4111');
  });

  testWidgets('bank autocomplete suggests Dominican banks', (tester) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.cards');
    await tester.tap(key('cards.emptyAdd'));
    await tester.pumpAndSettle();
    await tester.enterText(key('cardForm.bank'), 'pop');
    await tester.pumpAndSettle();
    await tester.tap(key('cardForm.bankOption.Banco Popular'));
    await tester.pumpAndSettle();
    expect(find.text('Banco Popular'), findsOneWidget);
  });

  testWidgets('another user\'s card id shows "not found"', (tester) async {
    final other = await seedUser(db, email: 'otro@example.com');
    final foreign = await seedCard(db, other.id!);
    await start(tester);
    final router = GoRouterHelper(tester);
    router.go('/home/cards/${foreign.id}');
    await tester.pumpAndSettle();
    expect(find.text('Tarjeta no encontrada'), findsOneWidget);
  });

  group('code review regressions', () {
    testWidgets('an archived card opened by URL shows "not found"', (
      tester,
    ) async {
      final card = await seedCard(db, userId, alias: 'Vieja');
      await db.db.update('cards', {'archived': 1});
      await start(tester);
      GoRouterHelper(tester).go('/home/cards/${card.id}');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tarjeta no encontrada'), findsOneWidget);
      GoRouterHelper(tester).go('/home/cards/${card.id}/edit');
      await tester.pumpAndSettle();
      expect(find.text('Tarjeta no encontrada'), findsOneWidget);
    });

    testWidgets('archive from detail → edit does not crash', (tester) async {
      final card = await seedCard(db, userId, alias: 'Viajes');
      await start(tester);
      await tapVisible(tester, 'home.carousel.${card.id}');
      await tester.tap(key('cardDetail.edit'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'cardForm.archive');
      await tester.tap(key('cardForm.archiveConfirm'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(key('cards.root'), findsOneWidget);
    });

    testWidgets('a typed limit must be greater than 0 and well formed', (
      tester,
    ) async {
      await start(tester);
      await tapVisible(tester, 'home.quick.cards');
      await tester.tap(key('cards.emptyAdd'));
      await tester.pumpAndSettle();
      await tester.enterText(key('cardForm.alias'), 'A');
      await tester.enterText(key('cardForm.bank'), 'Banco Prueba');
      await tester.enterText(key('cardForm.last4'), '1111');
      await tester.enterText(key('cardForm.cutDay'), '5');
      for (final bad in ['0', '1500,50']) {
        await tester.ensureVisible(key('cardForm.limit'));
        await tester.enterText(key('cardForm.limit'), bad);
        await tapVisible(tester, 'cardForm.save');
        expect(
          find.text('Monto no válido (ej. 50000 o 50,000.00)'),
          findsOneWidget,
          reason: bad,
        );
      }
      expect(await db.db.query('cards'), isEmpty);
    });

    testWidgets('a failed load shows an error, not "no cards"', (tester) async {
      final store = InMemorySecureStore()
        ..values['session_user_id'] = '$userId';
      await tester.pumpWidget(
        testApp([
          ...await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
            now: today,
          ),
          financeProvider.overrideWith((ref) => Future.error('disco')),
        ]),
      );
      await tester.pumpAndSettle();
      expect(key('home.loadError'), findsOneWidget);
      expect(key('home.addFirstCard'), findsNothing);
      expect(key('home.carouselEmpty'), findsNothing);
    });

    testWidgets('greeting and ranking refresh when the app resumes', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 22, 10);
      await seedCard(db, userId, alias: 'A', cutDay: 23);
      final store = InMemorySecureStore()
        ..values['session_user_id'] = '$userId';
      await tester.pumpWidget(
        testApp([
          ...await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
          ),
          clockProvider.overrideWithValue(() => now),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buenos días, María José'), findsOneWidget);
      expect(find.textContaining('Corta mañana'), findsOneWidget);

      // Back in the app the next evening.
      now = DateTime(2026, 10, 23, 20);
      // Real Android sequence when leaving and coming back.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text('Buenas noches, María José'), findsOneWidget);
      expect(find.textContaining('Corta hoy'), findsOneWidget);
    });
  });
}

/// Navigates with the app's router from a test.
class GoRouterHelper {
  GoRouterHelper(this.tester);

  final WidgetTester tester;

  void go(String location) {
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).go(location);
  }
}
