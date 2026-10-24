import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/billing_cycle.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/core/statement.dart';
import 'package:tarjetas_y_pagos/data/models/card_payment.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';

/// Card with cut day 5 and 20 days to pay. On 22 Oct 2026 the last closed
/// statement is the 5 Oct one, due 25 Oct.
void main() {
  final today = DateTime(2026, 10, 22);

  CreditCard card({bool dual = false, int limit = 0, int usdLimit = 0}) =>
      CreditCard(
        id: 1,
        userId: 1,
        alias: 'A',
        bank: 'B',
        brand: CardBrand.visa,
        last4: '1234',
        cutDay: 5,
        paymentDays: 20,
        creditLimitCents: limit,
        currency: Currency.dop,
        dualCurrency: dual,
        secondaryLimitCents: usdLimit,
        color: 0,
        createdAt: DateTime(2026),
      );

  Expense spent(int cents, DateTime date, {Currency currency = Currency.dop}) =>
      Expense(
        userId: 1,
        cardId: 1,
        categoryId: 1,
        merchant: 'M',
        amountCents: cents,
        currency: currency,
        date: date,
        createdAt: date,
      );

  CardPayment paid(
    int cents,
    DateTime date, {
    Currency currency = Currency.dop,
  }) => CardPayment(
    cardId: 1,
    amountCents: cents,
    currency: currency,
    date: date,
  );

  test('cut and due dates of the statement being paid', () {
    final s = statementFor(card(), [], [], today);
    expect(s.lastCut, DateTime.utc(2026, 10, 5));
    expect(s.dueDate, DateTime.utc(2026, 10, 25));
  });

  test('balance is all expenses minus all payments', () {
    final s = statementFor(
      card(),
      [
        spent(100000, DateTime(2026, 9, 20)),
        spent(50000, DateTime(2026, 10, 15)),
      ],
      [paid(30000, DateTime(2026, 10, 10))],
      today,
    );
    expect(s.balanceIn(Currency.dop), 120000);
  });

  test('only expenses up to the cut are due this cut', () {
    final s = statementFor(
      card(),
      [
        spent(100000, DateTime(2026, 9, 20)), // before cut → due
        spent(20000, DateTime(2026, 10, 5)), // on the cut day → due
        spent(50000, DateTime(2026, 10, 15)), // after cut → next statement
      ],
      [],
      today,
    );
    expect(s.byCurrency[Currency.dop]!.dueCents, 120000);
  });

  test('payments after the cut reduce what is due, never below 0', () {
    final partial = statementFor(
      card(),
      [spent(100000, DateTime(2026, 9, 20))],
      [paid(40000, DateTime(2026, 10, 12))],
      today,
    );
    expect(partial.byCurrency[Currency.dop]!.dueCents, 60000);

    final over = statementFor(
      card(),
      [spent(100000, DateTime(2026, 9, 20))],
      [paid(150000, DateTime(2026, 10, 12))],
      today,
    );
    expect(over.byCurrency[Currency.dop]!.dueCents, 0);
    expect(over.balanceIn(Currency.dop), -50000); // saldo a favor
  });

  test('older unpaid debt carries into this cut', () {
    final s = statementFor(
      card(),
      [
        spent(80000, DateTime(2026, 8, 20)), // two statements ago, unpaid
        spent(20000, DateTime(2026, 9, 20)),
      ],
      [paid(30000, DateTime(2026, 9, 1))], // paid before the cut
      today,
    );
    expect(s.byCurrency[Currency.dop]!.dueCents, 70000);
  });

  test('overdue only after the due date with money still owed', () {
    final expenses = [spent(100000, DateTime(2026, 9, 20))];
    expect(
      statementFor(
        card(),
        expenses,
        [],
        today,
      ).byCurrency[Currency.dop]!.overdue,
      isFalse,
    );
    final late = DateTime(2026, 10, 26);
    expect(
      statementFor(
        card(),
        expenses,
        [],
        late,
      ).byCurrency[Currency.dop]!.overdue,
      isTrue,
    );
    expect(
      statementFor(card(), expenses, [
        paid(100000, DateTime(2026, 10, 20)),
      ], late).byCurrency[Currency.dop]!.overdue,
      isFalse,
    );
  });

  test('dual card keeps RD\$ and US\$ apart', () {
    final s = statementFor(
      card(dual: true),
      [
        spent(100000, DateTime(2026, 9, 20)),
        spent(4000, DateTime(2026, 9, 21), currency: Currency.usd),
      ],
      [paid(1000, DateTime(2026, 10, 10), currency: Currency.usd)],
      today,
    );
    expect(s.byCurrency.keys, containsAll([Currency.dop, Currency.usd]));
    expect(s.balanceIn(Currency.dop), 100000);
    expect(s.balanceIn(Currency.usd), 3000);
    expect(s.byCurrency[Currency.usd]!.dueCents, 3000);
  });

  test('single-currency card lists only its currency when empty', () {
    expect(statementFor(card(), [], [], today).byCurrency.keys, [Currency.dop]);
  });

  test('spentInMonth sums the calendar month per currency', () {
    final totals = spentInMonth([
      spent(100000, DateTime(2026, 10, 1)),
      spent(50000, DateTime(2026, 10, 31)),
      spent(99999, DateTime(2026, 9, 30)), // previous month
      spent(99999, DateTime(2025, 10, 15)), // same month, last year
      spent(4000, DateTime(2026, 10, 2), currency: Currency.usd),
    ], today);
    expect(totals, {Currency.dop: 150000, Currency.usd: 4000});
  });

  group('available credit per currency', () {
    test('dual card is low credit if either currency is low', () {
      final c = card(dual: true, limit: 1000000, usdLimit: 100000);
      final ok = recommendationFor(
        c,
        today,
        balances: {Currency.dop: 500000, Currency.usd: 50000},
      );
      expect(ok.available, {Currency.dop: 500000, Currency.usd: 50000});
      expect(ok.lowCredit, isFalse);

      final usdLow = recommendationFor(
        c,
        today,
        balances: {Currency.usd: 95000},
      );
      expect(usdLow.available[Currency.usd], 5000);
      expect(usdLow.lowCredit, isTrue);
    });

    test('a currency without limit has no available amount', () {
      final r = recommendationFor(
        card(dual: true, limit: 1000000),
        today,
        balances: {Currency.usd: 999999},
      );
      expect(r.available.keys, [Currency.dop]);
      expect(r.lowCredit, isFalse);
    });
  });

  test('an unpaid statement stays overdue after the next cut', () {
    // Cut 15, 20 days to pay. The 15 Sep statement is due 5 Oct.
    final c = CreditCard(
      id: 1,
      userId: 1,
      alias: 'A',
      bank: 'B',
      brand: CardBrand.visa,
      last4: '1234',
      cutDay: 15,
      paymentDays: 20,
      currency: Currency.dop,
      color: 0,
      createdAt: DateTime(2026),
    );
    final expenses = [spent(100000, DateTime(2026, 9, 10))];

    // 10 Oct: late since 5 Oct.
    var s = statementFor(c, expenses, [], DateTime(2026, 10, 10));
    expect(s.byCurrency[Currency.dop]!.overdueCents, 100000);
    expect(s.byCurrency[Currency.dop]!.overdueSince, DateTime.utc(2026, 10, 5));

    // 16 Oct: the 15 Oct cut (due 4 Nov) is the new statement, but the
    // September money is still late.
    s = statementFor(c, expenses, [], DateTime(2026, 10, 16));
    expect(s.dueDate, DateTime.utc(2026, 11, 4));
    expect(s.byCurrency[Currency.dop]!.dueCents, 100000);
    expect(s.byCurrency[Currency.dop]!.overdueCents, 100000);
    expect(s.byCurrency[Currency.dop]!.overdueSince, DateTime.utc(2026, 10, 5));

    // Paying it clears the overdue amount.
    s = statementFor(c, expenses, [
      paid(100000, DateTime(2026, 10, 16)),
    ], DateTime(2026, 10, 16));
    expect(s.byCurrency[Currency.dop]!.overdue, isFalse);
  });

  test('long payment terms look back to the latest past due date', () {
    // Cut 5, 40 days to pay: on 22 Oct the 5 Oct cut is due 14 Nov (not
    // yet), so the late check uses the 5 Sep cut (due 15 Oct).
    final c = card().copyWith(paymentDays: 40);
    final s = statementFor(
      c,
      [spent(100000, DateTime(2026, 8, 20))],
      [],
      today,
    );
    expect(
      s.byCurrency[Currency.dop]!.overdueSince,
      DateTime.utc(2026, 10, 15),
    );
  });

  group('payBy', () {
    test('only the open cycle: the next cut\'s due date', () {
      final c = card();
      final s = statementFor(
        c,
        [spent(1000, DateTime(2026, 10, 10))],
        [],
        today,
      );
      expect(payBy(c, s, today), (
        date: dateOnly(DateTime(2026, 11, 25)),
        overdue: false,
      ));
    });

    test('a closed statement still owed: its due date', () {
      final c = card();
      final s = statementFor(
        c,
        [spent(1000, DateTime(2026, 9, 20))],
        [],
        today,
      );
      expect(payBy(c, s, today), (
        date: dateOnly(DateTime(2026, 10, 25)),
        overdue: false,
      ));
    });

    test('past it and unpaid: overdue since that date', () {
      final c = card();
      final late = DateTime(2026, 10, 27);
      final s = statementFor(c, [spent(1000, DateTime(2026, 9, 20))], [], late);
      expect(payBy(c, s, late), (
        date: dateOnly(DateTime(2026, 10, 25)),
        overdue: true,
      ));
    });

    test('a statement paid off: back to the next cut', () {
      final c = card();
      final s = statementFor(
        c,
        [spent(1000, DateTime(2026, 9, 20))],
        [paid(1000, DateTime(2026, 10, 20))],
        today,
      );
      expect(payBy(c, s, today).date, dateOnly(DateTime(2026, 11, 25)));
    });
  });
}
