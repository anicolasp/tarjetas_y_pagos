import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/core/notification_plan.dart';
import 'package:tarjetas_y_pagos/data/finance_snapshot.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';

/// Card 1 cuts on the 5th with 20 days to pay. On 22 Oct 2026 the 5 Oct
/// statement is due 25 Oct and the next cut is 5 Nov.
void main() {
  setUpAll(() => initializeDateFormatting(appLocale));

  final now = DateTime(2026, 10, 22, 8);

  CreditCard card({int id = 1, String alias = 'Visa Oro', int cutDay = 5}) =>
      CreditCard(
        id: id,
        userId: 1,
        alias: alias,
        bank: 'Banco Prueba',
        brand: CardBrand.visa,
        last4: '1234',
        cutDay: cutDay,
        paymentDays: 20,
        currency: Currency.dop,
        color: 0,
        createdAt: DateTime(2026),
      );

  Expense spent(int cardId, DateTime date) => Expense(
    userId: 1,
    cardId: cardId,
    categoryId: 1,
    merchant: 'Comercio',
    amountCents: 100000,
    currency: Currency.dop,
    date: date,
    createdAt: date,
  );

  Debt debt({int id = 1, DateTime? due, int amount = 50000}) => Debt(
    id: id,
    userId: 1,
    creditor: 'Juan',
    amountCents: amount,
    currency: Currency.dop,
    dueDate: due,
    createdAt: DateTime(2026, 9),
  );

  List<PlannedNotification> plan(
    FinanceSnapshot s, {
    DateTime? at,
    int days = 3,
  }) => planNotifications(s, now: at ?? now, daysBefore: days);

  test('cut − N at 9:00, with the alias and a stable id', () {
    final p = plan(
      FinanceSnapshot(cards: [card()], expenses: const [], payments: const []),
    );
    expect(p, hasLength(1)); // nothing owed: no payment reminder
    expect(p.single.id, notificationId(1, ReminderKind.cut));
    expect(p.single.at, DateTime(2026, 11, 2, 9));
    expect(p.single.body, 'Tu tarjeta Visa Oro corta en 3 días');
    expect(p.single.route, '/home/cards/1');
  });

  test('payment deadline − N when the card owes something', () {
    final s = FinanceSnapshot(
      cards: [card()],
      expenses: [spent(1, DateTime(2026, 10, 1))],
      payments: const [],
    );
    final pay = plan(s).firstWhere((n) => n.id == 5);
    expect(pay.at, DateTime(2026, 10, 22, 9));
    expect(pay.body, startsWith('Fecha límite de pago de Visa Oro: 25'));
  });

  test('times already past are left out', () {
    final s = FinanceSnapshot(
      cards: [card()],
      expenses: [spent(1, DateTime(2026, 10, 1))],
      payments: const [],
    );
    // At 10:00 the 9:00 payment reminder of today is gone; the cut stays.
    final p = plan(s, at: DateTime(2026, 10, 22, 10));
    expect(p.map((n) => n.id), [notificationId(1, ReminderKind.cut)]);
  });

  test('an overdue statement gets no deadline reminder', () {
    final s = FinanceSnapshot(
      cards: [card()],
      expenses: [spent(1, DateTime(2026, 9, 1))], // due 25 Sep, unpaid
      payments: const [],
    );
    expect(
      plan(s).where((n) => n.id == notificationId(1, ReminderKind.payment)),
      isEmpty,
    );
  });

  test('debts: active with a date only; settled and undated are skipped', () {
    final s = FinanceSnapshot(
      cards: const [],
      expenses: const [],
      payments: const [],
      debts: [
        debt(id: 1, due: DateTime(2026, 11, 10)),
        debt(id: 2, due: DateTime(2026, 11, 10)),
        debt(id: 3),
      ],
      debtPayments: [
        DebtPayment(debtId: 2, amountCents: 50000, date: DateTime(2026, 10)),
      ],
    );
    final p = plan(s);
    expect(p, hasLength(1));
    expect(p.single.id, notificationId(1, ReminderKind.debt));
    expect(p.single.at, DateTime(2026, 11, 7, 9));
    expect(p.single.body, startsWith('La deuda con Juan vence el 10'));
    expect(p.single.route, '/home/debts/1');
  });

  test('wording for 0 and 1 days', () {
    final s = FinanceSnapshot(
      cards: [card(cutDay: 25)],
      expenses: const [],
      payments: const [],
    );
    expect(plan(s, days: 0).single.body, 'Tu tarjeta Visa Oro corta hoy');
    expect(plan(s, days: 1).single.body, 'Tu tarjeta Visa Oro corta mañana');
  });

  test('ids never collide between cards, debts and kinds', () {
    final ids = {
      for (final id in [1, 2, 3])
        for (final k in ReminderKind.values) notificationId(id, k),
    };
    expect(ids, hasLength(9));
    expect(
      notificationId(7, ReminderKind.cut),
      notificationId(7, ReminderKind.cut),
    );
  });
}
