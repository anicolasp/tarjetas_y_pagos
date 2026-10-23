import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/card_payment.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';
import 'package:tarjetas_y_pagos/data/repositories/cards_repository.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';

import '../helpers/seed.dart';
import '../helpers/test_db.dart';

void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late ExpensesRepository repo;
  late int ana;
  late int otro;
  late int cardA;
  late int cardB;
  late int supermercado;
  late int combustible;

  setUp(() async {
    db = await openTestDatabase();
    repo = ExpensesRepository(db, clock: () => today);
    ana = (await seedUser(db, email: 'ana@example.com')).id!;
    otro = (await seedUser(db, email: 'otro@example.com')).id!;
    cardA = (await seedCard(db, ana, alias: 'A')).id!;
    cardB = (await seedCard(db, ana, alias: 'B')).id!;
    final cats = {for (final c in await repo.categories(ana)) c.name: c.id!};
    supermercado = cats['Supermercado']!;
    combustible = cats['Combustible']!;
  });

  tearDown(() => db.close());

  Expense expense({
    int? userId,
    int? cardId,
    int? categoryId,
    String merchant = 'Súper Prueba',
    int cents = 250000,
    Currency currency = Currency.dop,
    DateTime? date,
  }) => Expense(
    userId: userId ?? ana,
    cardId: cardId ?? cardA,
    categoryId: categoryId ?? supermercado,
    merchant: merchant,
    amountCents: cents,
    currency: currency,
    date: date ?? DateTime(2026, 10, 20),
    createdAt: today,
  );

  group('create', () {
    test('stores cents and trims text', () async {
      final e = await repo.create(
        expense(merchant: '  Súper Prueba  ', cents: 123456),
      );
      expect(e.id, isNotNull);
      expect(e.merchant, 'Súper Prueba');
      expect(e.amountCents, 123456);
      expect((await db.db.query('expenses')).single['amount_cents'], 123456);
    });

    test('validates amount, merchant, date, card, category, currency', () {
      for (final (reason, bad) in [
        ('amount 0', expense(cents: 0)),
        ('negative', expense(cents: -5)),
        ('no merchant', expense(merchant: '   ')),
        ('long merchant', expense(merchant: 'x' * 81)),
        ('future date', expense(date: DateTime(2026, 10, 23))),
        ('foreign card', expense(cardId: 9999)),
        ('unknown category', expense(categoryId: 9999)),
        ('USD on a RD\$ card', expense(currency: Currency.usd)),
      ]) {
        expect(() => repo.create(bad), throwsArgumentError, reason: reason);
      }
    });

    test('today is allowed', () async {
      await repo.create(expense(date: today));
    });

    test('cannot use another user\'s card', () async {
      final foreign = (await seedCard(db, otro)).id!;
      expect(() => repo.create(expense(cardId: foreign)), throwsArgumentError);
    });

    test('cannot add to an archived card', () async {
      await CardsRepository(db).archive(ana, cardB);
      expect(() => repo.create(expense(cardId: cardB)), throwsArgumentError);
    });

    test('records a conversion only when complete and consistent', () async {
      final converted = await repo.create(
        expense(cents: 245637).copyWith(
          originalAmountCents: 4000,
          originalCurrency: Currency.usd,
          exchangeRateMicros: 61409228,
        ),
      );
      expect(converted.wasConverted, isTrue);
      expect(converted.originalAmountCents, 4000);

      expect(
        () => repo.create(expense().copyWith(originalCurrency: Currency.usd)),
        throwsArgumentError,
      );
      expect(
        () => repo.create(
          expense().copyWith(
            originalAmountCents: 4000,
            originalCurrency: Currency.dop, // same as the card
            exchangeRateMicros: 1000000,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('dual card accepts both currencies', () async {
      final dual = await seedCard(db, ana, alias: 'Dual');
      await db.db.update(
        'cards',
        {'dual_currency': 1},
        where: 'id = ?',
        whereArgs: [dual.id],
      );
      await repo.create(expense(cardId: dual.id, currency: Currency.usd));
      await repo.create(expense(cardId: dual.id));
    });
  });

  group('filters', () {
    setUp(() async {
      await repo.create(
        expense(
          merchant: 'La Sirena',
          cents: 250000,
          date: DateTime(2026, 10, 1),
        ),
      );
      await repo.create(
        expense(merchant: 'Jumbo', cents: 80000, date: DateTime(2026, 10, 10)),
      );
      await repo.create(
        expense(
          merchant: 'Shell',
          cents: 300000,
          categoryId: combustible,
          date: DateTime(2026, 10, 15),
        ),
      );
      await repo.create(
        expense(
          cardId: cardB,
          merchant: 'Texaco 50%',
          cents: 150000,
          categoryId: combustible,
          date: DateTime(2026, 9, 30),
        ),
      );
      await repo.create(
        expense(userId: otro, cardId: (await seedCard(db, otro)).id),
      );
    });

    Future<List<String>> names(ExpenseFilter f) async =>
        (await repo.list(ana, f)).map((e) => e.merchant).toList();

    test('no filter: all of the user, newest first', () async {
      expect(await names(const ExpenseFilter()), [
        'Shell',
        'Jumbo',
        'La Sirena',
        'Texaco 50%',
      ]);
    });

    test('by card', () async {
      expect(await names(ExpenseFilter(cardId: cardB)), ['Texaco 50%']);
    });

    test('by categories (multi)', () async {
      expect(await names(ExpenseFilter(categoryIds: {combustible})), [
        'Shell',
        'Texaco 50%',
      ]);
      expect(
        (await names(ExpenseFilter(categoryIds: {combustible, supermercado})))
            .length,
        4,
      );
    });

    test('by date range, inclusive', () async {
      expect(
        await names(
          ExpenseFilter(
            from: DateTime(2026, 10, 1),
            to: DateTime(2026, 10, 10),
          ),
        ),
        ['Jumbo', 'La Sirena'],
      );
    });

    test('by merchant, case-insensitive, wildcards literal', () async {
      expect(await names(const ExpenseFilter(merchant: 'sire')), ['La Sirena']);
      expect(await names(const ExpenseFilter(merchant: '50%')), ['Texaco 50%']);
      expect(await names(const ExpenseFilter(merchant: '%')), ['Texaco 50%']);
      expect(await names(const ExpenseFilter(merchant: '_')), isEmpty);
    });

    test('by amount range, inclusive', () async {
      expect(
        await names(const ExpenseFilter(minCents: 150000, maxCents: 250000)),
        ['La Sirena', 'Texaco 50%'],
      );
    });

    test('combined', () async {
      expect(
        await names(
          ExpenseFilter(
            cardId: cardA,
            categoryIds: {supermercado},
            from: DateTime(2026, 10, 1),
            merchant: 'a',
            minCents: 100000,
          ),
        ),
        ['La Sirena'],
      );
    });

    test('another user never sees these expenses', () async {
      expect((await repo.list(otro)).length, 1);
    });
  });

  group('update and delete', () {
    test('update changes amount; only the owner can', () async {
      final e = await repo.create(expense());
      await repo.update(e.copyWith(amountCents: 99900));
      expect((await repo.getById(ana, e.id!))!.amountCents, 99900);

      final foreign = e.copyWith();
      await expectLater(
        repo.update(Expense.fromMap({...foreign.toMap(), 'user_id': otro})),
        throwsArgumentError, // otro cannot use Ana's card
      );
    });

    test('delete removes it; not found for another user', () async {
      final e = await repo.create(expense());
      await expectLater(repo.delete(otro, e.id!), throwsStateError);
      await repo.delete(ana, e.id!);
      expect(await repo.getById(ana, e.id!), isNull);
    });
  });

  group('payments', () {
    CardPayment payment({int? cardId, int cents = 100000, DateTime? date}) =>
        CardPayment(
          cardId: cardId ?? cardA,
          amountCents: cents,
          currency: Currency.dop,
          date: date ?? DateTime(2026, 10, 21),
        );

    test('add, list by card and delete', () async {
      final p = await repo.addPayment(ana, payment());
      await repo.addPayment(ana, payment(cardId: cardB));
      expect((await repo.payments(ana, cardId: cardA)).single.id, p.id);
      expect((await repo.payments(ana)).length, 2);
      await repo.deletePayment(ana, p.id!);
      expect(await repo.payments(ana, cardId: cardA), isEmpty);
    });

    test('validates amount, date, currency and ownership', () async {
      final foreign = (await seedCard(db, otro)).id!;
      for (final (reason, bad) in [
        ('amount 0', payment(cents: 0)),
        ('future', payment(date: DateTime(2026, 10, 23))),
        ('foreign card', payment(cardId: foreign)),
        (
          'USD on RD\$ card',
          CardPayment(
            cardId: cardA,
            amountCents: 100,
            currency: Currency.usd,
            date: DateTime(2026, 10, 1),
          ),
        ),
      ]) {
        await expectLater(
          repo.addPayment(ana, bad),
          throwsArgumentError,
          reason: reason,
        );
      }
    });

    test('another user cannot list or delete them', () async {
      final p = await repo.addPayment(ana, payment());
      expect(await repo.payments(otro), isEmpty);
      await expectLater(repo.deletePayment(otro, p.id!), throwsStateError);
    });
  });

  test('categories: base ones, "Otros" last', () async {
    final names = (await repo.categories(ana)).map((c) => c.name).toList();
    expect(names, hasLength(13));
    expect(names.last, 'Otros');
    expect(names.first, 'Agua');
  });
}
