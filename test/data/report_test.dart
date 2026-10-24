import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/core/report.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';

import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Report aggregation in SQL with known data. Card A is RD$, card B is US$.
void main() {
  late AppDatabase db;
  late ExpensesRepository repo;
  late int ana;
  late int cardA;
  late int cardB;
  late Map<String, int> cats;

  setUp(() async {
    db = await openTestDatabase();
    repo = ExpensesRepository(db, clock: () => DateTime(2026, 10, 22));
    ana = (await seedUser(db, email: 'ana@example.com')).id!;
    final otro = (await seedUser(db, email: 'otro@example.com')).id!;
    cardA = (await seedCard(db, ana, alias: 'A')).id!;
    cardB = (await seedCard(db, ana, alias: 'B', currency: Currency.usd)).id!;
    cats = {for (final c in await repo.categories(ana)) c.name: c.id!};

    // Ana, RD$: Supermercado 100 + 250 (Oct), Combustible 300 (Sep).
    await seedExpense(
      db,
      ana,
      cardA,
      'Supermercado',
      'Sirena',
      cents: 10000,
      date: DateTime(2026, 10, 3),
    );
    await seedExpense(
      db,
      ana,
      cardA,
      'Supermercado',
      'Nacional',
      cents: 25000,
      date: DateTime(2026, 10, 18),
    );
    await seedExpense(
      db,
      ana,
      cardA,
      'Combustible',
      'Texaco',
      cents: 30000,
      date: DateTime(2026, 9, 9),
    );
    // Ana, US$: Restaurante 40 (Oct) on card B.
    await seedExpense(
      db,
      ana,
      cardB,
      'Restaurante',
      'Diner',
      cents: 4000,
      date: DateTime(2026, 10, 5),
      currency: Currency.usd,
    );
    // Another user: never counted.
    final otroCard = (await seedCard(db, otro)).id!;
    await seedExpense(
      db,
      otro,
      otroCard,
      'Supermercado',
      'Ajeno',
      cents: 999900,
      date: DateTime(2026, 10, 3),
    );
  });

  tearDown(() => db.close());

  test('totals, average and count per currency, never mixed', () async {
    final r = await repo.report(ana);
    expect(r.currencies, [Currency.dop, Currency.usd]);
    final dop = r.totals[Currency.dop]!;
    expect(dop.totalCents, 65000);
    expect(dop.count, 3);
    expect(dop.averageCents, 21667); // 650 / 3 = 216.666… → 216.67
    final usd = r.totals[Currency.usd]!;
    expect((usd.totalCents, usd.count, usd.averageCents), (4000, 1, 4000));
  });

  test('GROUP BY category, month and card', () async {
    final r = await repo.report(ana);
    expect(
      r.categoriesIn(Currency.dop).map((t) => (t.categoryId, t.totalCents)),
      [(cats['Supermercado'], 35000), (cats['Combustible'], 30000)],
    );
    expect(r.categoriesIn(Currency.dop).first.count, 2);
    expect(r.monthsIn(Currency.dop).map((m) => (m.month, m.totalCents)), [
      (DateTime(2026, 9), 30000),
      (DateTime(2026, 10), 35000),
    ]);
    expect(r.cardsIn(Currency.dop).map((t) => (t.cardId, t.totalCents)), [
      (cardA, 65000),
    ]);
    expect(r.cardsIn(Currency.usd).map((t) => (t.cardId, t.totalCents)), [
      (cardB, 4000),
    ]);
  });

  test('the report uses the same filters as the list', () async {
    final filter = ExpenseFilter(
      cardIds: {cardA},
      categoryIds: {cats['Supermercado']!},
      from: DateTime(2026, 10),
      to: DateTime(2026, 10, 31),
    );
    final r = await repo.report(ana, filter);
    final listed = await repo.list(ana, filter);
    expect(r.currencies, [Currency.dop]);
    expect(r.totals[Currency.dop]!.count, listed.length);
    expect(
      r.totals[Currency.dop]!.totalCents,
      listed.fold(0, (s, e) => s + e.amountCents),
    );
    expect(r.totals[Currency.dop]!.totalCents, 35000);
  });

  test('several cards at once', () async {
    final both = await repo.report(ana, ExpenseFilter(cardIds: {cardA, cardB}));
    expect(both.currencies, [Currency.dop, Currency.usd]);
    final onlyB = await repo.report(ana, ExpenseFilter(cardIds: {cardB}));
    expect(onlyB.currencies, [Currency.usd]);
  });

  test('nothing matches: an empty report', () async {
    final r = await repo.report(
      ana,
      const ExpenseFilter(merchant: 'no existe'),
    );
    expect(r.isEmpty, isTrue);
    expect(r.categoriesIn(Currency.dop), isEmpty);
  });

  group('ExpenseReport helpers', () {
    test('months without expenses are 0 within the period', () async {
      final r = await repo.report(ana);
      expect(
        r
            .monthsIn(
              Currency.dop,
              from: DateTime(2026, 8, 1),
              to: DateTime(2026, 10, 31),
            )
            .map((m) => (m.month.month, m.totalCents)),
        [(8, 0), (9, 30000), (10, 35000)],
      );
      expect(r.monthsIn(Currency.usd).length, 1);
    });

    test('top 5 categories plus "Resto"', () {
      final r = ExpenseReport(
        totals: const {},
        byCategory: [
          for (var i = 1; i <= 8; i++)
            (
              categoryId: i,
              currency: Currency.dop,
              totalCents: i * 100,
              count: 1,
            ),
        ],
        byMonth: const [],
        byCard: const [],
      );
      final (:top, :rest) = r.topCategoriesIn(Currency.dop);
      expect(top.map((t) => t.categoryId), [8, 7, 6, 5, 4]);
      expect(rest, (categories: 3, totalCents: 600));
    });

    test('six categories are all shown (a one-item "Resto" helps nobody)', () {
      final r = ExpenseReport(
        totals: const {},
        byCategory: [
          for (var i = 1; i <= 6; i++)
            (categoryId: i, currency: Currency.dop, totalCents: 100, count: 1),
        ],
        byMonth: const [],
        byCard: const [],
      );
      final (:top, :rest) = r.topCategoriesIn(Currency.dop);
      expect(top.map((t) => t.categoryId), [1, 2, 3, 4, 5, 6]); // ties by id
      expect(rest, isNull);
    });

    test('average rounds half up', () {
      CurrencyTotals t(int total, int n) =>
          CurrencyTotals(currency: Currency.dop, totalCents: total, count: n);
      expect(t(5, 2).averageCents, 3); // 2.5 → 3
      expect(t(4, 3).averageCents, 1); // 1.33 → 1
      expect(t(0, 0).averageCents, 0);
    });

    test('quick periods', () {
      final today = DateTime(2026, 1, 15);
      expect(ReportPeriod.thisMonth.rangeFor(today), (
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      ));
      expect(ReportPeriod.lastMonth.rangeFor(today), (
        from: DateTime(2025, 12, 1),
        to: DateTime(2025, 12, 31),
      ));
      expect(ReportPeriod.last3Months.rangeFor(today), (
        from: DateTime(2025, 11, 1),
        to: DateTime(2026, 1, 31),
      ));
      expect(ReportPeriod.custom.rangeFor(today), isNull);
      // February in a leap year.
      expect(
        ReportPeriod.thisMonth.rangeFor(DateTime(2028, 2, 10))!.to,
        DateTime(2028, 2, 29),
      );
    });
  });
}
