import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/cards_repository.dart';

import '../helpers/seed.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late CardsRepository repo;
  late int ana;
  late int otro;

  setUp(() async {
    db = await openTestDatabase();
    repo = CardsRepository(db, clock: () => DateTime(2026, 10, 22, 9));
    ana = (await seedUser(db, email: 'ana@example.com')).id!;
    otro = (await seedUser(db, email: 'otro@example.com')).id!;
  });

  tearDown(() => db.close());

  test('create trims and stores only the last 4 digits', () async {
    final card = await seedCard(db, ana, alias: '  Gastos  ', last4: '0042');
    expect(card.id, isNotNull);
    expect(card.alias, 'Gastos');
    expect(card.last4, '0042');
    final row = (await db.db.query('cards')).single;
    expect(row.values.whereType<String>().join(' '), isNot(contains('4111')));
  });

  test('create rejects invalid data', () async {
    final valid = await seedCard(db, ana);
    for (final bad in [
      valid.copyWith(alias: '  '),
      valid.copyWith(bank: ''),
      valid.copyWith(last4: '123'),
      valid.copyWith(last4: '12345'),
      valid.copyWith(last4: '12a4'),
      valid.copyWith(cutDay: 0),
      valid.copyWith(cutDay: 32),
      valid.copyWith(paymentDays: -1),
      valid.copyWith(paymentDays: 61),
      valid.copyWith(creditLimitCents: -1),
    ]) {
      expect(() => repo.create(bad), throwsArgumentError);
    }
  });

  test('lists only the user\'s active cards, in creation order', () async {
    await seedCard(db, ana, alias: 'A');
    await seedCard(db, ana, alias: 'B');
    await seedCard(db, otro, alias: 'De otro');
    expect((await repo.listActive(ana)).map((c) => c.alias), ['A', 'B']);
    expect((await repo.listActive(otro)).map((c) => c.alias), ['De otro']);
  });

  test('getById never returns another user\'s card', () async {
    final card = await seedCard(db, otro);
    expect(await repo.getById(ana, card.id!), isNull);
    expect(await repo.getById(otro, card.id!), isNotNull);
  });

  test('update changes the card of its owner only', () async {
    final card = await seedCard(db, ana);
    await repo.update(card.copyWith(creditLimitCents: 5000000, cutDay: 31));
    final updated = (await repo.getById(ana, card.id!))!;
    expect(updated.creditLimitCents, 5000000);
    expect(updated.cutDay, 31);

    // Ana cannot update another user's card by using its id.
    final foreign = await seedCard(db, otro, alias: 'De otro');
    await expectLater(
      repo.update(card.copyWith(id: foreign.id, alias: 'Robada')),
      throwsStateError,
    );
    expect((await repo.getById(otro, foreign.id!))!.alias, 'De otro');
  });

  test('archive hides the card and keeps its data', () async {
    final a = await seedCard(db, ana, alias: 'A');
    await seedCard(db, ana, alias: 'B');
    await repo.archive(ana, a.id!);
    expect((await repo.listActive(ana)).map((c) => c.alias), ['B']);
    expect((await repo.getById(ana, a.id!))!.archived, isTrue);
    await expectLater(repo.archive(otro, a.id!), throwsStateError);
  });

  test('a currency with movements cannot be dropped from a card', () async {
    final card = await seedCard(db, ana);
    await seedExpense(db, ana, card.id!, 'Supermercado', 'Jumbo');
    await expectLater(
      repo.update(card.copyWith(currency: Currency.usd)),
      throwsArgumentError,
    );
    // Turning dual on keeps RD$, so it is allowed.
    await repo.update(card.copyWith(dualCurrency: true));
    final dual = (await repo.getById(ana, card.id!))!;
    expect(dual.dualCurrency, isTrue);
    // A US$ expense on the dual card blocks turning dual off again.
    await seedExpense(
      db,
      ana,
      card.id!,
      'Supermercado',
      'Amazon',
      currency: Currency.usd,
    );
    await expectLater(
      repo.update(dual.copyWith(dualCurrency: false)),
      throwsArgumentError,
    );
  });
}
