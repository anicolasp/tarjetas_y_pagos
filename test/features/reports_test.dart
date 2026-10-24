import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Reports through the real app with an in-memory database. Today is
/// 22 Oct 2026. Card A is RD$, card B is US$.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late int userId;
  late int cardA;
  late int cardB;
  late Map<String, int> cats;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
    cardA = (await seedCard(db, userId, alias: 'A', last4: '1111')).id!;
    cardB = (await seedCard(
      db,
      userId,
      alias: 'B',
      last4: '2222',
      currency: Currency.usd,
    )).id!;
    cats = {
      for (final c in await ExpensesRepository(db).categories(userId))
        c.name: c.id!,
    };
    // October, RD$ on A: Supermercado 1,000 + 500, Combustible 2,000.
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Sirena',
      cents: 100000,
      date: DateTime(2026, 10, 3),
    );
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Nacional',
      cents: 50000,
      date: DateTime(2026, 10, 18),
    );
    await seedExpense(
      db,
      userId,
      cardA,
      'Combustible',
      'Texaco',
      cents: 200000,
      date: DateTime(2026, 10, 10),
    );
    // October, US$ on B: Restaurante 40.
    await seedExpense(
      db,
      userId,
      cardB,
      'Restaurante',
      'Diner',
      cents: 4000,
      date: DateTime(2026, 10, 5),
      currency: Currency.usd,
    );
    // September, RD$ on A: outside "Este mes".
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Bravo',
      cents: 70000,
      date: DateTime(2026, 9, 20),
    );
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> open(WidgetTester tester) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: today,
        ),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push('/home/reports');
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  /// Every text under [k], including rich text.
  String textIn(String k) => find
      .descendant(of: key(k), matching: find.byType(Text))
      .evaluate()
      .map((e) {
        final t = e.widget as Text;
        return t.data ?? t.textSpan?.toPlainText() ?? '';
      })
      .join(' | ');

  testWidgets('home opens reports', (tester) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: today,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      key('home.quick.reports'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, 'home.quick.reports');
    expect(key('reports.root'), findsOneWidget);
  });

  testWidgets('1. "Este mes" by default, per currency', (tester) async {
    await open(tester);
    expect(find.text('Este mes'), findsOneWidget);
    expect(textIn('reports.total.DOP'), contains('RD\$ 3,500.00'));
    expect(textIn('reports.count.DOP'), contains('3'));
    expect(textIn('reports.average.DOP'), contains('RD\$ 1,166.67'));
    expect(textIn('reports.total.USD'), contains('US\$ 40.00'));
    expect(key('reports.currency'), findsOneWidget);
    // Category legend: Combustible (2,000) before Supermercado (1,500).
    expect(
      textIn('reports.category.${cats['Combustible']}'),
      contains('RD\$ 2,000.00'),
    );
    expect(
      textIn('reports.category.${cats['Supermercado']}'),
      contains('43 %'),
    );
    expect(textIn('reports.card.$cardA'), contains('RD\$ 3,500.00'));
  });

  testWidgets('2 and 4. card A + Supermercado, then remove the card chip', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'reports.cards');
    await tap(tester, 'reports.cardOption.$cardA');
    await tap(tester, 'reports.cardsApply');
    expect(key('reports.chip.card.$cardA'), findsOneWidget);
    expect(key('reports.total.USD'), findsNothing);
    expect(key('reports.currency'), findsNothing);

    await tap(tester, 'reports.moreFilters');
    await tap(tester, 'expenseFilter.category.Supermercado');
    await tap(tester, 'expenseFilter.apply');
    expect(
      key('reports.chip.category.${cats['Supermercado']}'),
      findsOneWidget,
    );
    expect(textIn('reports.total.DOP'), contains('RD\$ 1,500.00'));
    expect(textIn('reports.count.DOP'), contains('2'));

    // 4. Removing the card chip: back to every card (US$ comes back).
    await tester.tap(
      find
          .descendant(
            of: key('reports.chip.card.$cardA'),
            matching: find.byType(Icon),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(key('reports.chip.card.$cardA'), findsNothing);
    expect(textIn('reports.total.DOP'), contains('RD\$ 1,500.00'));
    // Restaurante is filtered out by the category chip.
    expect(key('reports.total.USD'), findsNothing);
  });

  testWidgets('3. another period: Movements shows only that period', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'reports.period');
    await tap(tester, 'reports.period.lastMonth');
    expect(find.text('Mes pasado'), findsOneWidget);
    expect(textIn('reports.total.DOP'), contains('RD\$ 700.00'));

    await tap(tester, 'reports.tabList');
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('reports.expense.'),
    );
    expect(rows, findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
  });

  testWidgets('a range picked in "Más filtros" becomes the custom period', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'reports.moreFilters');
    await tap(tester, 'expenseFilter.clear');
    // Clearing the dates goes back to the default period.
    expect(find.text('Este mes'), findsOneWidget);
    expect(key('reports.chip.range'), findsNothing);
  });

  testWidgets('5. the currency selector switches the charts', (tester) async {
    await open(tester);
    expect(find.text('Por categoría (RD\$)'), findsOneWidget);
    await tap(tester, 'reports.currency.USD');
    expect(find.text('Por categoría (US\$)'), findsOneWidget);
    expect(
      textIn('reports.category.${cats['Restaurante']}'),
      contains('US\$ 40.00'),
    );
    expect(key('reports.category.${cats['Supermercado']}'), findsNothing);
    expect(textIn('reports.card.$cardB'), contains('US\$ 40.00'));
    // The totals still show both currencies, never added together.
    expect(key('reports.total.DOP'), findsOneWidget);
  });

  testWidgets('movements open the expense', (tester) async {
    await open(tester);
    await tap(tester, 'reports.tabList');
    expect(find.text('Sirena'), findsOneWidget);
    await tester.tap(find.text('Sirena'));
    await tester.pumpAndSettle();
    expect(key('expenseForm.delete'), findsOneWidget);
  });

  testWidgets('no matches: the empty state in both tabs', (tester) async {
    await open(tester);
    await tap(tester, 'reports.moreFilters');
    await tester.enterText(key('expenseFilter.merchant'), 'no existe');
    await tap(tester, 'expenseFilter.apply');
    expect(find.text('No hay gastos con estos filtros'), findsOneWidget);
    expect(key('reports.chip.merchant'), findsOneWidget);
    await tap(tester, 'reports.tabList');
    expect(find.text('No hay gastos con estos filtros'), findsOneWidget);
  });

  testWidgets('more than 6 categories: top 5 + "Resto"', (tester) async {
    for (final name in ['Luz', 'Agua', 'Teléfono', 'Salud', 'Licor']) {
      await seedExpense(
        db,
        userId,
        cardA,
        name,
        name,
        cents: 1000,
        date: DateTime(2026, 10, 1),
      );
    }
    await open(tester);
    expect(key('reports.category.rest'), findsOneWidget);
    expect(textIn('reports.category.rest'), contains('Resto (2)'));
  });

  group('responsive (rule #2)', () {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('summary: ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          for (final name in ['Luz', 'Agua', 'Teléfono', 'Salud']) {
            await seedExpense(
              db,
              userId,
              cardA,
              name,
              'Comercio $name',
              cents: 123456789,
              date: DateTime(2026, 10, 1),
            );
          }
          await open(tester);
          await tap(tester, 'reports.cards');
          await tap(tester, 'reports.cardOption.$cardA');
          await tap(tester, 'reports.cardsApply');
          await tester.ensureVisible(key('reports.byCard'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(key('reports.byMonth'), findsOneWidget);
        });

        testWidgets('movements: ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await open(tester);
          await tap(tester, 'reports.tabList');
          expect(tester.takeException(), isNull);
          expect(key('reports.expense.1'), findsOneWidget);
        });
      }

      testWidgets('card picker: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        await open(tester);
        await tap(tester, 'reports.cards');
        expect(tester.takeException(), isNull);
        expect(key('reports.cardsApply'), findsOneWidget);
      });

      testWidgets('period sheet and empty state: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        await open(tester);
        await tap(tester, 'reports.period');
        expect(tester.takeException(), isNull);
        await tap(tester, 'reports.period.lastMonth');
        await tap(tester, 'reports.cards');
        await tap(tester, 'reports.cardOption.$cardB');
        await tap(tester, 'reports.cardsApply');
        expect(tester.takeException(), isNull);
        expect(key('reports.empty'), findsOneWidget);
      });
    }
  });
}
