import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/repositories/debts_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Debts through the real app with an in-memory database. Today is
/// 22 Oct 2026. Creditor names are fictitious.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late int userId;
  late int cardId;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
    // Card A (cut 5): RD$ 1,500 owed.
    cardId = (await seedCard(db, userId, alias: 'A', cutDay: 5)).id!;
    await seedExpense(
      db,
      userId,
      cardId,
      'Supermercado',
      'Sirena',
      cents: 150000,
      date: DateTime(2026, 10, 10),
    );
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(WidgetTester tester, {String? path}) async {
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
    if (path != null) {
      GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, String k) async {
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

  String textIn(String k) => find
      .descendant(of: key(k), matching: find.byType(Text), matchRoot: true)
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .join(' | ');

  Future<Debt> seedDebt({
    String creditor = 'Préstamo Ficticio',
    int cents = 1000000,
    Currency currency = Currency.dop,
    DateTime? due,
    String? description,
  }) => DebtsRepository(db, clock: () => today).create(
    Debt(
      userId: userId,
      creditor: creditor,
      description: description,
      amountCents: cents,
      currency: currency,
      dueDate: due ?? DateTime(2026, 11, 21),
      createdAt: DateTime(2026, 10, 1),
    ),
  );

  Future<void> addPayment(Debt d, int cents) =>
      DebtsRepository(db, clock: () => today).addPayment(
        userId,
        DebtPayment(debtId: d.id!, amountCents: cents, date: today),
      );

  testWidgets('E2E 1–5: cards, new debt, two payments, settled, Home total', (
    tester,
  ) async {
    await start(tester);
    expect(textIn('home.debt.DOP'), contains('RD\$ 1,500.00'));

    // 1. Home → Deudas: the card balance is there.
    await tap(tester, 'home.quick.debts');
    expect(textIn('debts.card.$cardId.DOP'), contains('RD\$ 1,500.00'));
    expect(key('debts.empty'), findsOneWidget);

    // 2. Nueva deuda: Préstamo Juan, RD$ 10,000, due in 30 days.
    await tap(tester, 'debts.add');
    await tester.enterText(key('debtForm.creditor'), 'Préstamo Juan');
    await tap(tester, 'debtForm.currency.DOP');
    await tester.enterText(key('debtForm.amount'), '10000');
    await tap(tester, 'debtForm.dueDate');
    await tester.tap(find.text('21')); // the picker opens 30 days ahead
    await tester.tap(
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextButton),
          )
          .last, // confirm
    );
    await tester.pumpAndSettle();
    expect(find.text(formatDate(DateTime(2026, 11, 21))), findsOneWidget);
    await tap(tester, 'debtForm.save');
    final debt = (await DebtsRepository(db).list(userId)).single;
    expect(debt.amountCents, 1000000);
    expect(debt.dueDate, DateTime(2026, 11, 21));
    expect(textIn('debt.${debt.id}.remaining'), contains('RD\$ 10,000.00'));

    // 3. Abono de RD$ 4,000 → falta 6,000, 40 %.
    await tap(tester, 'debts.debt.${debt.id}');
    await tap(tester, 'debtDetail.addPayment');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: key('debtPayment.amount'),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '10000.00', // prefilled with what is left
    );
    await tester.enterText(key('debtPayment.amount'), '4000');
    await tap(tester, 'debtPayment.save');
    expect(textIn('debt.${debt.id}.remaining'), contains('RD\$ 6,000.00'));
    expect(find.text('40 % pagado'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(key('debt.${debt.id}.progress'))
          .value,
      0.4,
    );

    // 4. Abono de RD$ 6,000 → Saldada.
    await tap(tester, 'debtDetail.addPayment');
    await tester.enterText(key('debtPayment.amount'), '6000');
    await tap(tester, 'debtPayment.save');
    expect(key('debtDetail.settled'), findsOneWidget);
    expect(key('debtDetail.addPayment'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(key('debts.debt.${debt.id}'), findsNothing); // not in Activas
    await tap(tester, 'debts.tabSettled');
    expect(key('debts.debt.${debt.id}'), findsOneWidget);

    // 5. Home: back to the cards' debt only.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(textIn('home.debt.DOP'), contains('RD\$ 1,500.00'));
  });

  testWidgets('Home total adds other debts, split shown, never mixed', (
    tester,
  ) async {
    final d = await seedDebt(cents: 1000000);
    await addPayment(d, 400000);
    await seedDebt(
      creditor: 'Tío Ficticio',
      cents: 5000,
      currency: Currency.usd,
    );
    await start(tester);
    // RD$ 1,500 (card) + 6,000 (left of the loan).
    expect(textIn('home.debt.DOP'), contains('RD\$ 7,500.00'));
    expect(
      textIn('home.debtSplit.DOP'),
      'Tarjetas RD\$ 1,500.00 · Otras deudas RD\$ 6,000.00',
    );
    expect(textIn('home.debt.USD'), contains('US\$ 50.00'));
  });

  group('card due date', () {
    String payBy(WidgetTester tester) => textIn('debts.card.$cardId.payBy');

    testWidgets('balance of the open cycle: the next cut\'s due date', (
      tester,
    ) async {
      // Spent on 10 Oct, after the 5 Oct cut: due with the 5 Nov cut.
      await start(tester, path: '/home/debts');
      expect(find.text('Fecha límite 25/nov'), findsOneWidget);
    });

    testWidgets('a closed statement still owed: its due date', (tester) async {
      await seedExpense(
        db,
        userId,
        cardId,
        'Otros',
        'Antes del corte',
        cents: 1000,
        date: DateTime(2026, 9, 20),
      );
      await start(tester, path: '/home/debts');
      expect(find.text('Fecha límite 25/oct'), findsOneWidget);
      expect(payBy(tester), isNot(contains('Vencido')));
    });

    testWidgets('past it and unpaid: "Vencido" in red with an icon', (
      tester,
    ) async {
      await seedExpense(
        db,
        userId,
        cardId,
        'Otros',
        'Antes del corte',
        cents: 1000,
        date: DateTime(2026, 9, 20),
      );
      final store = InMemorySecureStore()
        ..values['session_user_id'] = '$userId';
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
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/debts');
      await tester.pumpAndSettle();
      expect(find.text('Vencido desde el 25/oct'), findsOneWidget);
      expect(
        find.descendant(
          of: key('debts.card.$cardId.payBy'),
          matching: find.byIcon(Icons.warning_amber),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('an overdue debt says "Vencida" with an icon', (tester) async {
    final d = await seedDebt(due: DateTime(2026, 10, 15));
    await start(tester, path: '/home/debts');
    expect(textIn('debt.${d.id}.due'), contains('Vencida el 15/10/2026'));
    expect(
      find.descendant(
        of: key('debt.${d.id}.due'),
        matching: find.byIcon(Icons.warning_amber),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a payment greater than what is left is not accepted', (
    tester,
  ) async {
    final d = await seedDebt(cents: 100000);
    await start(tester, path: '/home/debts/${d.id}/pay');
    await tester.enterText(key('debtPayment.amount'), '1000.01');
    await tap(tester, 'debtPayment.save');
    expect(find.text('Máximo RD\$ 1,000.00'), findsOneWidget);
    expect(await DebtsRepository(db).payments(userId), isEmpty);
  });

  testWidgets('deleting the last payment brings a settled debt back', (
    tester,
  ) async {
    final d = await seedDebt(cents: 100000);
    await addPayment(d, 100000);
    final payment = (await DebtsRepository(db).payments(userId)).single;
    await start(tester, path: '/home/debts/${d.id}');
    expect(key('debtDetail.settled'), findsOneWidget);
    await tap(tester, 'debtDetail.payment.${payment.id}');
    await tap(tester, 'debtDetail.deletePaymentConfirm');
    expect(key('debtDetail.addPayment'), findsOneWidget);
    expect(textIn('debt.${d.id}.remaining'), contains('RD\$ 1,000.00'));
  });

  testWidgets('edit: currency locked with payments; amount not below paid', (
    tester,
  ) async {
    final d = await seedDebt(cents: 100000);
    await addPayment(d, 60000);
    await start(tester, path: '/home/debts/${d.id}/edit');
    expect(
      tester.widget<ChoiceChip>(key('debtForm.currency.USD')).onSelected,
      isNull,
    );
    await tester.enterText(key('debtForm.amount'), '500');
    await tap(tester, 'debtForm.save');
    expect(find.text('Ya abonaste RD\$ 600.00'), findsOneWidget);
  });

  testWidgets('an old due date still opens the date picker', (tester) async {
    final d = await seedDebt(due: DateTime(2019, 6, 1));
    await start(tester, path: '/home/debts/${d.id}/edit');
    await tap(tester, 'debtForm.dueDate');
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('99.5 % paid reads 99 % on screen and to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final d = await seedDebt(cents: 10000);
    await addPayment(d, 9950);
    await start(tester, path: '/home/debts');
    expect(find.text('99 % pagado'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'99 % pagado')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'100 %')), findsNothing);
    semantics.dispose();
  });

  testWidgets('delete a debt from its form', (tester) async {
    final d = await seedDebt();
    await start(tester, path: '/home/debts/${d.id}/edit');
    await tap(tester, 'debtForm.delete');
    await tap(tester, 'debtForm.deleteConfirm');
    expect(key('debts.root'), findsOneWidget);
    expect(await DebtsRepository(db).list(userId), isEmpty);
  });

  testWidgets('form validation: creditor and amount', (tester) async {
    await start(tester, path: '/home/debts/new');
    await tap(tester, 'debtForm.save');
    expect(find.text('Escribe a quién le debes'), findsOneWidget);
    expect(find.text('Escribe un monto mayor que 0'), findsOneWidget);
  });

  group('responsive (rule #2)', () {
    Future<int> stress() async {
      final d = await seedDebt(
        creditor: 'Cooperativa de ahorros y préstamos del barrio',
        description: 'Préstamo para reparar el techo de la casa y la cocina',
        cents: 123456789,
        due: DateTime(2026, 10, 15),
      );
      await addPayment(d, 2345678);
      await addPayment(d, 1000000);
      await seedDebt(creditor: 'Tío Ficticio', currency: Currency.usd);
      return d.id!;
    }

    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        for (final (name, path) in [
          ('list', '/home/debts'),
          ('detail', '/home/debts/:id'),
          ('form', '/home/debts/:id/edit'),
          ('payment', '/home/debts/:id/pay'),
        ]) {
          testWidgets('$name: ${c.name}, ${brightness.name}', (tester) async {
            setScreen(tester, c.size, c.textScale);
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            final id = await stress();
            await start(tester, path: path.replaceAll(':id', '$id'));
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(
                ValueKey(switch (name) {
                  'list' => 'debts.root',
                  'detail' => 'debtDetail.root',
                  'form' => 'debtForm.root',
                  _ => 'debtPayment.root',
                }),
              ),
              findsOneWidget,
            );
          });
        }
      }

      testWidgets('settled tab and empty states: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        await start(tester, path: '/home/debts');
        await tap(tester, 'debts.tabSettled');
        expect(tester.takeException(), isNull);
        expect(key('debts.settledEmpty'), findsOneWidget);
      });
    }
  });
}
