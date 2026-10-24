import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/debts.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/repositories/debts_repository.dart';

import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Creditor names are fictitious.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late DebtsRepository repo;
  late int ana;
  late int otro;

  setUp(() async {
    db = await openTestDatabase();
    repo = DebtsRepository(db, clock: () => today);
    ana = (await seedUser(db, email: 'ana@example.com')).id!;
    otro = (await seedUser(db, email: 'otro@example.com')).id!;
  });

  tearDown(() => db.close());

  Future<Debt> debt({
    int? userId,
    int cents = 1000000,
    Currency currency = Currency.dop,
    DateTime? due,
  }) => repo.create(
    Debt(
      userId: userId ?? ana,
      creditor: '  Préstamo Juan Ficticio ',
      description: '  ',
      amountCents: cents,
      currency: currency,
      dueDate: due ?? DateTime(2026, 11, 21),
      createdAt: DateTime(2026, 10, 1),
    ),
  );

  DebtPayment pay(Debt d, int cents, {DateTime? date}) => DebtPayment(
    debtId: d.id!,
    amountCents: cents,
    date: date ?? DateTime(2026, 10, 22),
  );

  Future<DebtSummary> summaryOf(Debt d) async => summarize(
    (await repo.getById(d.userId, d.id!))!,
    await repo.payments(d.userId),
  );

  test('create trims the creditor and drops an empty description', () async {
    final d = await debt();
    expect(d.creditor, 'Préstamo Juan Ficticio');
    expect(d.description, isNull);
    expect(d.status, DebtStatus.active);
  });

  test('validation: creditor and a positive amount', () async {
    expect(
      () => repo.create(
        Debt(
          userId: ana,
          creditor: ' ',
          amountCents: 100,
          currency: Currency.dop,
          createdAt: today,
        ),
      ),
      throwsArgumentError,
    );
    expect(() => debt(cents: 0), throwsArgumentError);
  });

  test('remaining and progress after a payment', () async {
    final d = await debt();
    await repo.addPayment(ana, pay(d, 400000));
    final s = await summaryOf(d);
    expect(s.paidCents, 400000);
    expect(s.remainingCents, 600000);
    expect(s.progress, 0.4);
    expect(s.debt.status, DebtStatus.active);
  });

  test('paying what is left settles it automatically', () async {
    final d = await debt();
    await repo.addPayment(ana, pay(d, 400000));
    await repo.addPayment(ana, pay(d, 600000));
    final s = await summaryOf(d);
    expect(s.remainingCents, 0);
    expect(s.settled, isTrue);
    expect(s.debt.status, DebtStatus.settled);
  });

  test('a payment greater than what is left is rejected', () async {
    final d = await debt();
    await repo.addPayment(ana, pay(d, 400000));
    await expectLater(
      repo.addPayment(ana, pay(d, 600001)),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('mayor que lo que falta'),
        ),
      ),
    );
    expect((await summaryOf(d)).paidCents, 400000);
    // A settled debt takes nothing more.
    await repo.addPayment(ana, pay(d, 600000));
    expect(() => repo.addPayment(ana, pay(d, 1)), throwsArgumentError);
  });

  test('payment dates: not in the future, not before the debt', () async {
    final d = await debt();
    expect(
      () => repo.addPayment(ana, pay(d, 100, date: DateTime(2026, 10, 23))),
      throwsArgumentError,
    );
    expect(
      () => repo.addPayment(ana, pay(d, 100, date: DateTime(2026, 9, 30))),
      throwsArgumentError,
    );
    expect(() => repo.addPayment(ana, pay(d, 0)), throwsArgumentError);
  });

  test('deleting a payment of a settled debt makes it active again', () async {
    final d = await debt();
    await repo.addPayment(ana, pay(d, 400000));
    final last = await repo.addPayment(ana, pay(d, 600000));
    await repo.deletePayment(ana, last.id!);
    final s = await summaryOf(d);
    expect(s.debt.status, DebtStatus.active);
    expect(s.remainingCents, 600000);
  });

  test(
    'the amount cannot go below what was paid; raising it reopens',
    () async {
      final d = await debt();
      await repo.addPayment(ana, pay(d, 1000000));
      expect((await repo.getById(ana, d.id!))!.status, DebtStatus.settled);
      expect(
        () => repo.update(d.copyWith(amountCents: 999999)),
        throwsArgumentError,
      );
      final raised = await repo.update(d.copyWith(amountCents: 1200000));
      expect(raised.status, DebtStatus.active);
      expect((await summaryOf(raised)).remainingCents, 200000);
    },
  );

  test('every query is scoped by user', () async {
    final mine = await debt();
    final theirs = await debt(userId: otro);
    await repo.addPayment(otro, pay(theirs, 100));

    expect((await repo.list(ana)).map((d) => d.id), [mine.id]);
    expect(await repo.payments(ana), isEmpty);
    expect(await repo.getById(ana, theirs.id!), isNull);
    expect(() => repo.addPayment(ana, pay(theirs, 100)), throwsStateError);
    expect(
      () => repo
          .update(theirs.copyWith(creditor: 'X'))
          .then((_) => fail('updated')),
      throwsA(anything),
    );
    final theirPayment = (await repo.payments(otro)).single;
    expect(() => repo.deletePayment(ana, theirPayment.id!), throwsStateError);
    expect(() => repo.delete(ana, theirs.id!), throwsStateError);
  });

  test('deleting a debt deletes its payments', () async {
    final d = await debt();
    await repo.addPayment(ana, pay(d, 100));
    await repo.delete(ana, d.id!);
    expect(await repo.list(ana), isEmpty);
    expect(await repo.payments(ana), isEmpty);
  });

  test('list: soonest due date first, without one last', () async {
    final late = await debt(due: DateTime(2027, 1, 1));
    final soon = await debt(due: DateTime(2026, 10, 30));
    final none = await repo.create(
      Debt(
        userId: ana,
        creditor: 'Sin fecha',
        amountCents: 100,
        currency: Currency.usd,
        createdAt: today,
      ),
    );
    expect((await repo.list(ana)).map((d) => d.id), [
      soon.id,
      late.id,
      none.id,
    ]);
  });

  group('DebtSummary', () {
    Debt d({DateTime? due}) => Debt(
      id: 1,
      userId: 1,
      creditor: 'Ficticio',
      amountCents: 1000,
      currency: Currency.dop,
      dueDate: due,
      createdAt: today,
    );

    test('overdue only when past due with something left', () {
      final past = d(due: DateTime(2026, 10, 21));
      expect(summarize(past, const []).overdue(today), isTrue);
      expect(
        summarize(past, [
          DebtPayment(debtId: 1, amountCents: 1000, date: today),
        ]).overdue(today),
        isFalse,
      );
      // Due today is not late yet.
      expect(
        summarize(d(due: DateTime(2026, 10, 22)), const []).overdue(today),
        isFalse,
      );
      expect(summarize(d(), const []).overdue(today), isFalse);
    });

    test('only its own payments count', () {
      final s = summarize(d(), [
        DebtPayment(debtId: 1, amountCents: 300, date: today),
        DebtPayment(debtId: 2, amountCents: 999, date: today),
      ]);
      expect(s.paidCents, 300);
      expect(s.progress, 0.3);
    });
  });
}
