import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/billing_cycle.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

CreditCard card(
  String alias, {
  int id = 1,
  int cutDay = 15,
  int paymentDays = 20,
  int limitCents = 0,
  bool archived = false,
}) => CreditCard(
  id: id,
  userId: 1,
  alias: alias,
  bank: 'Banco Prueba',
  brand: CardBrand.visa,
  last4: '1234',
  cutDay: cutDay,
  paymentDays: paymentDays,
  creditLimitCents: limitCents,
  currency: Currency.dop,
  color: 0,
  archived: archived,
  createdAt: DateTime(2026),
);

void main() {
  group('cutInMonth clamps to the month length', () {
    test('day 31 in April is the 30th', () {
      expect(cutInMonth(2026, 4, 31), d(2026, 4, 30));
    });
    test('day 29 in February of a non-leap year is the 28th', () {
      expect(cutInMonth(2026, 2, 29), d(2026, 2, 28));
      expect(cutInMonth(2026, 2, 31), d(2026, 2, 28));
    });
    test('leap year keeps February 29', () {
      expect(cutInMonth(2028, 2, 29), d(2028, 2, 29));
    });
    test('month 13 and 0 roll the year', () {
      expect(cutInMonth(2026, 13, 5), d(2027, 1, 5));
      expect(cutInMonth(2026, 0, 31), d(2025, 12, 31));
    });
  });

  group('nextCut', () {
    test('before the cut day: this month', () {
      expect(nextCut(d(2026, 10, 3), 5), d(2026, 10, 5));
    });
    test('a purchase on the cut day belongs to that cut', () {
      expect(nextCut(d(2026, 10, 5), 5), d(2026, 10, 5));
    });
    test('after the cut day: next month', () {
      expect(nextCut(d(2026, 10, 6), 5), d(2026, 11, 5));
    });
    test('December rolls to January of next year', () {
      expect(nextCut(d(2026, 12, 20), 15), d(2027, 1, 15));
    });
    test('cut 31 after April 30 goes to May 31', () {
      expect(nextCut(d(2026, 4, 30), 31), d(2026, 4, 30));
      expect(nextCut(d(2026, 5, 1), 31), d(2026, 5, 31));
    });
    test('ignores the time of day', () {
      expect(nextCut(DateTime(2026, 10, 5, 23, 59), 5), d(2026, 10, 5));
    });
  });

  group('lastCut', () {
    test('is the cut before the next one', () {
      expect(lastCut(d(2026, 10, 3), 5), d(2026, 9, 5));
      expect(lastCut(d(2026, 10, 6), 5), d(2026, 10, 5));
    });
    test('on the cut day the previous cut is last month', () {
      expect(lastCut(d(2026, 10, 5), 5), d(2026, 9, 5));
    });
    test('January goes back to December', () {
      expect(lastCut(d(2027, 1, 10), 15), d(2026, 12, 15));
    });
    test('clamps in short months', () {
      expect(lastCut(d(2026, 3, 15), 31), d(2026, 2, 28));
    });
  });

  test('dueDate adds the payment days across months and years', () {
    expect(dueDate(d(2026, 10, 25), 20), d(2026, 11, 14));
    expect(dueDate(d(2026, 12, 25), 20), d(2027, 1, 14));
  });

  group('financingDays', () {
    test('right after the cut gives the most days', () {
      // Cut 5, today Oct 6 → next cut Nov 5, due Nov 25 → 50 days.
      expect(financingDays(d(2026, 10, 6), 5, 20), 50);
    });
    test('on the cut day gives only the payment days', () {
      expect(financingDays(d(2026, 10, 5), 5, 20), 20);
    });
  });

  group('rankCards', () {
    final today = d(2026, 10, 22);

    test('orders by most financing days', () {
      final a = card('A', id: 1, cutDay: 5); // next Nov 5 → due Nov 25: 34
      final b = card('B', id: 2, cutDay: 25); // next Oct 25 → due Nov 14: 23
      final c = card('C', id: 3, cutDay: 21); // next Nov 21 → due Dec 11: 50
      final ranked = rankCards([a, b, c], today);
      expect(ranked.map((r) => r.card.alias), ['C', 'A', 'B']);
      expect(ranked.map((r) => r.financingDays), [50, 34, 23]);
      expect(ranked.first.nextCut, d(2026, 11, 21));
      expect(ranked.first.dueDate, d(2026, 12, 11));
    });

    test('excludes archived cards', () {
      final ranked = rankCards([
        card('A', id: 1),
        card('B', id: 2, archived: true),
      ], today);
      expect(ranked.map((r) => r.card.alias), ['A']);
    });

    test('low credit (< 10 %) goes last with a warning', () {
      final best = card('Mejor', id: 1, cutDay: 21, limitCents: 100000);
      final ok = card('Normal', id: 2, cutDay: 25, limitCents: 100000);
      final ranked = rankCards(
        [best, ok],
        today,
        balances: {
          1: {Currency.dop: 95000},
        }, // 5 % left
      );
      expect(ranked.map((r) => r.card.alias), ['Normal', 'Mejor']);
      expect(ranked.last.lowCredit, isTrue);
      expect(ranked.last.availableCents, 5000);
      expect(ranked.first.lowCredit, isFalse);
    });

    test('exactly 10 % is not low credit', () {
      final ranked = rankCards(
        [card('A', limitCents: 100000)],
        today,
        balances: {
          1: {Currency.dop: 90000},
        },
      );
      expect(ranked.single.lowCredit, isFalse);
    });

    test('no limit registered: no available amount and no warning', () {
      final ranked = rankCards(
        [card('A')],
        today,
        balances: {
          1: {Currency.dop: 50000},
        },
      );
      expect(ranked.single.availableCents, isNull);
      expect(ranked.single.lowCredit, isFalse);
    });

    test('ties: more available credit, then alias', () {
      final ranked = rankCards([
        card('b', id: 1, limitCents: 100000),
        card('A', id: 2, limitCents: 100000),
        card('C', id: 3, limitCents: 500000),
        card('Z', id: 4),
      ], today);
      expect(ranked.map((r) => r.card.alias), ['C', 'A', 'b', 'Z']);
    });
  });

  test('recommendationFor works for archived cards too', () {
    final r = recommendationFor(
      card('A', cutDay: 5, limitCents: 100000, archived: true),
      d(2026, 10, 22),
      balances: {Currency.dop: 30000},
    );
    expect(r.nextCut, d(2026, 11, 5));
    expect(r.dueDate, d(2026, 11, 25));
    expect(r.financingDays, 34);
    expect(r.availableCents, 70000);
  });
}
