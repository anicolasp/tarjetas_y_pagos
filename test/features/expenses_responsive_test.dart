import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/card_payment.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Rule #2 for the #5 screens: no overflow on small phones, landscape,
/// tablets and text x2, in light and dark. Data is chosen to stress the
/// layout: a dual card with limits, a converted expense, a payment, an
/// overdue statement and long names.
void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting(appLocale));
  setUp(() async => db = await openTestDatabase());
  tearDown(() => db.close());

  Future<({int dualId, int expenseId, int singleId})> seed() async {
    final user = await seedUser(db);
    final dual = await seedCard(
      db,
      user.id!,
      alias: 'Gastos del supermercado y la casa',
      cutDay: 5,
      limitCents: 123456789,
    );
    await db.db.update(
      'cards',
      {'dual_currency': 1, 'secondary_limit_cents': 500000},
      where: 'id = ?',
      whereArgs: [dual.id],
    );
    final expense = await seedExpense(
      db,
      user.id!,
      dual.id!,
      'Supermercado',
      'Supermercado Nacional de la avenida principal',
      cents: 98765432,
      date: DateTime(2026, 9, 20),
    );
    await seedExpense(
      db,
      user.id!,
      dual.id!,
      'Restaurante',
      'Restaurante',
      cents: 4000,
      currency: Currency.usd,
    );
    await ExpensesRepository(
      db,
      clock: () => DateTime(2026, 10, 22),
    ).addPayment(
      user.id!,
      CardPayment(
        cardId: dual.id!,
        amountCents: 100000,
        currency: Currency.dop,
        date: DateTime(2026, 10, 21),
        note: 'Pago parcial por banca en línea',
      ),
    );
    final single = await seedCard(
      db,
      user.id!,
      alias: 'Solo pesos',
      last4: '9999',
    );
    return (dualId: dual.id!, expenseId: expense.id!, singleId: single.id!);
  }

  Future<void> open(WidgetTester tester, String location) async {
    final ids = await seed();
    final store = InMemorySecureStore()..values['session_user_id'] = '1';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          // After the due date: the statement shows "Vencido".
          now: DateTime(2026, 10, 27, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final path = location
        .replaceAll(':card', '${ids.dualId}')
        .replaceAll(':expense', '${ids.expenseId}')
        .replaceAll(':single', '${ids.singleId}');
    if (path != '/home') {
      GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
      await tester.pumpAndSettle();
    }
  }

  final screens = <String, ({String location, String root})>{
    'home with debt': (location: '/home', root: 'home.debt.DOP'),
    'card detail': (location: '/home/cards/:card', root: 'cardDetail.due.USD'),
    'new expense': (
      location: '/home/expenses/new?cardId=:card',
      root: 'expenseForm.root',
    ),
    'edit expense': (
      location: '/home/expenses/:expense',
      root: 'expenseForm.delete',
    ),
    'payment form': (
      location: '/home/cards/:card/pay',
      root: 'paymentForm.currency.USD',
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

          await open(tester, s.location);

          expect(tester.takeException(), isNull);
          expect(find.byKey(ValueKey(s.root)), findsOneWidget);
        });
      }
    }
  }

  for (final c in responsiveCases) {
    testWidgets('filter sheet: ${c.name}', (tester) async {
      setScreen(tester, c.size, c.textScale);
      await open(tester, '/home/cards/:card');
      await tester.tap(find.byKey(const ValueKey('cardDetail.filter')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('expenseFilter.root')), findsOneWidget);
    });

    testWidgets('expense form converting US\$ on a RD\$ card: ${c.name}', (
      tester,
    ) async {
      setScreen(tester, c.size, c.textScale);
      // A single-currency card, then pick US$ → rate field + preview.
      await open(tester, '/home/expenses/new?cardId=:single');
      await tester.ensureVisible(
        find.byKey(const ValueKey('expenseForm.currency.USD')),
      );
      await tester.tap(find.byKey(const ValueKey('expenseForm.currency.USD')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('expenseForm.rate')), findsOneWidget);
    });
  }
}
