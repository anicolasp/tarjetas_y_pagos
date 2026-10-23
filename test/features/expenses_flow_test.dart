import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/features/cards/cards_providers.dart';

import '../helpers/fakes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Expenses, payments, balances and filters through the real app with an
/// in-memory database. "Today" is Thursday 22 Oct 2026, 10:00. Card A cuts
/// on the 5th (last cut 5 Oct, due 25 Oct), card B on the 25th.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late int userId;
  late int cardA;
  late int cardB;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
    cardA = (await seedCard(
      db,
      userId,
      alias: 'A',
      cutDay: 5,
      last4: '1111',
    )).id!;
    cardB = (await seedCard(
      db,
      userId,
      alias: 'B',
      cutDay: 25,
      last4: '2222',
      currency: Currency.usd,
    )).id!;
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(WidgetTester tester, {FakeRateSource? rates}) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: today,
          rates: rates,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, String k) async {
    // Lazily built lists (Home) only create what is on screen: scroll until
    // the element exists, then make it fully visible.
    if (key(k).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        key(k),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  Future<void> fillExpense(
    WidgetTester tester, {
    required String merchant,
    required String category,
    required String amount,
    String? currency,
  }) async {
    await tester.enterText(key('expenseForm.merchant'), merchant);
    await tapVisible(tester, 'expenseForm.category.$category');
    if (currency != null) {
      await tapVisible(tester, 'expenseForm.currency.$currency');
    }
    await tester.ensureVisible(key('expenseForm.amount'));
    await tester.enterText(key('expenseForm.amount'), amount);
    await tester.pumpAndSettle();
  }

  testWidgets('steps 1–2: from the card, A is preselected; balance rises', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    expect(key('cardDetail.root'), findsOneWidget);
    expect(key('cardDetail.empty'), findsOneWidget);

    await tester.tap(key('cardDetail.addExpense'));
    await tester.pumpAndSettle();
    expect(find.text('A •••• 1111'), findsOneWidget); // preselected
    await fillExpense(
      tester,
      merchant: 'La Sirena',
      category: 'Supermercado',
      amount: '2500',
    );
    await tapVisible(tester, 'expenseForm.save');

    expect(key('cardDetail.root'), findsOneWidget);
    expect(find.text('La Sirena'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(
      tester.widget<Text>(key('cardDetail.balanceValue.DOP')).data,
      'RD\$ 2,500.00',
    );
    // Bought after the 5 Oct cut → nothing due this cut yet.
    expect(tester.widget<Text>(key('cardDetail.due.DOP')).data, 'RD\$ 0.00');
  });

  testWidgets('step 3: from Home, pick card B and register US\$ 40', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.expense');
    await tester.tap(key('expenseForm.card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B •••• 2222').last);
    await tester.pumpAndSettle();
    await fillExpense(
      tester,
      merchant: 'Shell',
      category: 'Combustible',
      amount: '40',
    );
    // B is a US$ card: no conversion needed.
    expect(key('expenseForm.rate'), findsNothing);
    await tapVisible(tester, 'expenseForm.save');

    expect(key('home.root'), findsOneWidget);
    expect(
      find.descendant(
        of: key('home.spent.USD'),
        matching: find.text('US\$ 40.00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('step 4: filter by category, then clear', (tester) async {
    final super_ = await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Jumbo',
    );
    await seedExpense(db, userId, cardA, 'Combustible', 'Texaco');
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    expect(find.text('Jumbo'), findsOneWidget);
    expect(find.text('Texaco'), findsOneWidget);

    await tester.tap(key('cardDetail.filter'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'expenseFilter.category.Supermercado');
    await tapVisible(tester, 'expenseFilter.apply');
    expect(find.text('Jumbo'), findsOneWidget);
    expect(find.text('Texaco'), findsNothing);
    expect(key('cardDetail.expense.${super_.id}'), findsOneWidget);

    await tapVisible(tester, 'cardDetail.clearFilter');
    expect(find.text('Texaco'), findsOneWidget);
  });

  testWidgets('filter with no results shows a message', (tester) async {
    await seedExpense(db, userId, cardA, 'Supermercado', 'Jumbo');
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    await tester.tap(key('cardDetail.filter'));
    await tester.pumpAndSettle();
    await tester.enterText(key('expenseFilter.merchant'), 'nada');
    await tapVisible(tester, 'expenseFilter.apply');
    expect(find.text('Ningún gasto coincide con los filtros'), findsOneWidget);
  });

  testWidgets('step 5: a payment lowers the balance and what is due', (
    tester,
  ) async {
    // Bought before the 5 Oct cut → due this cut.
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Jumbo',
      cents: 250000,
      date: DateTime(2026, 9, 28),
    );
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    expect(
      tester.widget<Text>(key('cardDetail.due.DOP')).data,
      'RD\$ 2,500.00',
    );
    expect(find.textContaining('Paga antes del 25 oct'), findsOneWidget);

    await tapVisible(tester, 'cardDetail.pay');
    await tester.enterText(key('paymentForm.amount'), '1000');
    await tapVisible(tester, 'paymentForm.save');

    expect(
      tester.widget<Text>(key('cardDetail.balanceValue.DOP')).data,
      'RD\$ 1,500.00',
    );
    expect(
      tester.widget<Text>(key('cardDetail.due.DOP')).data,
      'RD\$ 1,500.00',
    );
    expect(find.text('Pago'), findsOneWidget);
  });

  testWidgets('payment shortcut fills what is due; payments can be deleted', (
    tester,
  ) async {
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Jumbo',
      cents: 250000,
      date: DateTime(2026, 9, 28),
    );
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    await tapVisible(tester, 'cardDetail.pay');
    await tapVisible(tester, 'paymentForm.fillDue');
    await tapVisible(tester, 'paymentForm.save');
    expect(tester.widget<Text>(key('cardDetail.due.DOP')).data, 'RD\$ 0.00');

    final payment = (await db.db.query('card_payments')).single['id'];
    await tapVisible(tester, 'cardDetail.payment.$payment');
    await tester.tap(key('cardDetail.deletePaymentConfirm'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(key('cardDetail.due.DOP')).data,
      'RD\$ 2,500.00',
    );
  });

  testWidgets('overpaying shows "Saldo a favor"', (tester) async {
    await seedExpense(db, userId, cardA, 'Supermercado', 'Jumbo', cents: 1000);
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    await tapVisible(tester, 'cardDetail.pay');
    await tester.enterText(key('paymentForm.amount'), '50');
    await tapVisible(tester, 'paymentForm.save');
    expect(find.text('Saldo a favor (DOP)'), findsOneWidget);
    expect(
      tester.widget<Text>(key('cardDetail.balanceValue.DOP')).data,
      'RD\$ 40.00',
    );
  });

  testWidgets('overdue when the due date passed with money owed', (
    tester,
  ) async {
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Jumbo',
      date: DateTime(2026, 9, 28),
    );
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: DateTime(2026, 10, 27, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, 'home.carousel.$cardA');
    expect(
      find.text('Vencido: RD\$ 1,000.00 desde el 25 oct 2026'),
      findsOneWidget,
    );
  });

  testWidgets('step 6: edit the amount, balance updates, then delete', (
    tester,
  ) async {
    final e = await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Jumbo',
      cents: 250000,
    );
    await start(tester);
    await tapVisible(tester, 'home.carousel.$cardA');
    await tapVisible(tester, 'cardDetail.expense.${e.id}');
    expect(find.text('Editar gasto'), findsOneWidget);
    await tester.enterText(key('expenseForm.amount'), '3000');
    await tapVisible(tester, 'expenseForm.save');
    expect(
      tester.widget<Text>(key('cardDetail.balanceValue.DOP')).data,
      'RD\$ 3,000.00',
    );

    await tapVisible(tester, 'cardDetail.expense.${e.id}');
    await tapVisible(tester, 'expenseForm.delete');
    await tester.tap(key('expenseForm.deleteConfirm'));
    await tester.pumpAndSettle();
    expect(key('cardDetail.empty'), findsOneWidget);
    expect(
      tester.widget<Text>(key('cardDetail.balanceValue.DOP')).data,
      'RD\$ 0.00',
    );
  });

  group('currency conversion', () {
    testWidgets('US\$ 40 on a RD\$ card uses the online rate', (tester) async {
      await start(tester);
      await tapVisible(tester, 'home.carousel.$cardA');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      await fillExpense(
        tester,
        merchant: 'Amazon',
        category: 'Otros',
        amount: '40',
        currency: 'USD',
      );
      expect(key('expenseForm.rate'), findsOneWidget);
      expect(find.text('61.409228'), findsOneWidget);
      expect(
        find.text('Se registra en la tarjeta como RD\$ 2,456.37'),
        findsOneWidget,
      );
      await tapVisible(tester, 'expenseForm.save');

      final row = (await db.db.query('expenses')).single;
      expect(row['amount_cents'], 245637);
      expect(row['currency'], 'DOP');
      expect(row['original_amount_cents'], 4000);
      expect(row['original_currency'], 'USD');
      expect(row['exchange_rate_micros'], 61409228);
      expect(find.textContaining('US\$ 40.00 a 61.409228'), findsOneWidget);
    });

    testWidgets('the rate can be adjusted to the bank\'s', (tester) async {
      await start(tester);
      await tapVisible(tester, 'home.carousel.$cardA');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      await fillExpense(
        tester,
        merchant: 'Amazon',
        category: 'Otros',
        amount: '40',
        currency: 'USD',
      );
      await tester.enterText(key('expenseForm.rate'), '60');
      await tester.pumpAndSettle();
      expect(
        find.text('Se registra en la tarjeta como RD\$ 2,400.00'),
        findsOneWidget,
      );
    });

    testWidgets('offline without a known rate asks to type it', (tester) async {
      await start(tester, rates: FakeRateSource(null));
      await tapVisible(tester, 'home.carousel.$cardA');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      await fillExpense(
        tester,
        merchant: 'Amazon',
        category: 'Otros',
        amount: '40',
        currency: 'USD',
      );
      expect(
        find.text('No se pudo obtener la tasa. Escríbela.'),
        findsOneWidget,
      );
      await tapVisible(tester, 'expenseForm.save');
      expect(find.text('Escribe la tasa (ej. 61.40)'), findsOneWidget);
      expect(await db.db.query('expenses'), isEmpty);
    });

    testWidgets('RD\$ on a US\$ card divides by the rate', (tester) async {
      await start(tester);
      await tapVisible(tester, 'home.carousel.$cardB');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      await fillExpense(
        tester,
        merchant: 'Colmado',
        category: 'Supermercado',
        amount: '6140.92',
        currency: 'DOP',
      );
      expect(
        find.text('Se registra en la tarjeta como US\$ 100.00'),
        findsOneWidget,
      );
    });

    testWidgets('a dual card keeps each currency without converting', (
      tester,
    ) async {
      await db.db.update(
        'cards',
        {
          'dual_currency': 1,
          'credit_limit_cents': 10000000,
          'secondary_limit_cents': 100000,
        },
        where: 'id = ?',
        whereArgs: [cardA],
      );
      await start(tester);
      await tapVisible(tester, 'home.carousel.$cardA');
      expect(key('cardDetail.balance.DOP'), findsOneWidget);
      expect(key('cardDetail.balance.USD'), findsOneWidget);

      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      await fillExpense(
        tester,
        merchant: 'Amazon',
        category: 'Otros',
        amount: '40',
        currency: 'USD',
      );
      expect(key('expenseForm.rate'), findsNothing);
      await tapVisible(tester, 'expenseForm.save');
      expect(
        tester.widget<Text>(key('cardDetail.balanceValue.USD')).data,
        'US\$ 40.00',
      );
      expect(
        find.text('Disponible US\$ 960.00 de US\$ 1,000.00'),
        findsOneWidget,
      );
    });
  });

  testWidgets('form validation: merchant, category, amount, card', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, 'home.quick.expense');
    await tapVisible(tester, 'expenseForm.save');
    expect(find.text('Escribe el comercio'), findsOneWidget);
    expect(find.text('Elige una categoría'), findsOneWidget);
    expect(find.text('Escribe un monto mayor que 0'), findsOneWidget);
    expect(find.text('Elige una tarjeta'), findsOneWidget);
    expect(await db.db.query('expenses'), isEmpty);
  });

  testWidgets('"Nuevo gasto" without cards asks to add one first', (
    tester,
  ) async {
    await db.db.update('cards', {'archived': 1});
    await start(tester);
    await tapVisible(tester, 'home.quick.expense');
    expect(key('expenseForm.noCards'), findsOneWidget);
    await tester.tap(key('expenseForm.addCard'));
    await tester.pumpAndSettle();
    expect(key('cardForm.root'), findsOneWidget);
  });

  testWidgets('Home: month spend, debt and ranking use real balances', (
    tester,
  ) async {
    await db.db.update(
      'cards',
      {'credit_limit_cents': 100000},
      where: 'id = ?',
      whereArgs: [cardA],
    );
    // A (best by days) is 95 % used → low credit → goes last.
    await seedExpense(db, userId, cardA, 'Supermercado', 'Jumbo', cents: 95000);
    await seedExpense(
      db,
      userId,
      cardA,
      'Supermercado',
      'Mes pasado',
      cents: 5000,
      date: DateTime(2026, 9, 10),
    );
    await start(tester);
    expect(
      find.descendant(
        of: key('home.spent.DOP'),
        matching: find.text('RD\$ 950.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('home.debt.DOP'),
        matching: find.text('RD\$ 1,000.00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: key('home.rank.0'),
        matching: find.textContaining('B'),
      ),
      findsWidgets,
    );
    expect(key('home.lowCredit.$cardA'), findsOneWidget);
  });

  group('code review regressions', () {
    testWidgets('card selection survives a data reload', (tester) async {
      await start(tester);
      await tapVisible(tester, 'home.carousel.$cardA');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      // Coming back from the background reloads the finance snapshot.
      final container = ProviderScope.containerOf(
        tester.element(key('expenseForm.root')),
      );
      container.invalidate(financeProvider);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('A •••• 1111'), findsOneWidget);
    });

    testWidgets('an expense of an archived card is read-only', (tester) async {
      final e = await seedExpense(db, userId, cardA, 'Supermercado', 'Jumbo');
      await db.db.update(
        'cards',
        {'archived': 1},
        where: 'id = ?',
        whereArgs: [cardA],
      );
      await start(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/expenses/${e.id}');
      await tester.pumpAndSettle();
      expect(key('expenseForm.archivedCard'), findsOneWidget);
      expect(key('expenseForm.save'), findsNothing);
      expect(key('expenseForm.delete'), findsOneWidget);
      // It never moves to card B.
      expect(find.text('B •••• 2222'), findsNothing);
    });

    testWidgets('a late online rate does not replace a typed one', (
      tester,
    ) async {
      final slow = SlowRateSource();
      await start(tester, rates: slow);
      await tapVisible(tester, 'home.carousel.$cardA');
      await tester.tap(key('cardDetail.addExpense'));
      await tester.pumpAndSettle();
      // The rate spinner keeps animating while the answer is pending, so
      // pump frames instead of waiting to settle.
      await tester.ensureVisible(key('expenseForm.currency.USD'));
      await tester.tap(key('expenseForm.currency.USD'));
      await tester.pump();
      await tester.enterText(key('expenseForm.rate'), '60.10');
      await tester.pump();
      slow.answer.complete(61409228);
      await tester.pumpAndSettle();
      expect(find.text('60.10'), findsOneWidget);
    });

    testWidgets('editing an old expense opens the date picker', (tester) async {
      final e = await seedExpense(
        db,
        userId,
        cardA,
        'Supermercado',
        'Vieja',
        date: DateTime(2019, 3, 1),
      );
      await start(tester);
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/expenses/${e.id}');
      await tester.pumpAndSettle();
      await tapVisible(tester, 'expenseForm.date');
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}

/// A rate source that answers only when the test completes [answer].
class SlowRateSource extends FakeRateSource {
  final answer = Completer<int>();

  @override
  Future<int> fetchUsdToDopMicros() => answer.future;
}
