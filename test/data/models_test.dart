import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/card_payment.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';

import '../helpers/test_db.dart';

/// Every model must survive toMap → fromMap → toMap unchanged.
void expectRoundTrip<T>(
  Map<String, Object?> Function(T) toMap,
  T Function(Map<String, Object?>) fromMap,
  T model,
) {
  final map = toMap(model);
  expect(toMap(fromMap(map)), map);
}

void main() {
  final created = DateTime(2026, 10, 21, 14, 30, 5);
  final day = DateTime(2026, 10, 15);

  final user = AppUser(
    id: 1,
    firstName: 'María José',
    lastName: 'Pérez',
    email: 'mj@example.com',
    passwordHash: 'hash',
    salt: 'salt',
    biometricEnabled: true,
    themeMode: ThemeMode.dark,
    defaultCurrency: Currency.usd,
    notifyDaysBefore: 5,
    createdAt: created,
  );
  final card = CreditCard(
    id: 2,
    userId: 1,
    alias: 'Gastos',
    bank: 'Banco Prueba',
    brand: CardBrand.mastercard,
    last4: '0042',
    cutDay: 31,
    paymentDays: 22,
    creditLimitCents: 15000000,
    currency: Currency.dop,
    color: 0xFF123456,
    archived: true,
    createdAt: created,
  );
  const category = Category(
    id: 3,
    userId: 1,
    name: 'Mascotas',
    icon: 'pets',
    color: 1,
  );
  final expense = Expense(
    id: 4,
    userId: 1,
    cardId: 2,
    categoryId: 3,
    merchant: 'Súper Prueba',
    amountCents: 250000,
    currency: Currency.dop,
    date: day,
    notes: 'semana',
    source: ExpenseSource.ai,
    createdAt: created,
  );
  final payment = CardPayment(
    id: 5,
    cardId: 2,
    amountCents: 100000,
    currency: Currency.dop,
    date: day,
  );
  final debt = Debt(
    id: 6,
    userId: 1,
    creditor: 'Acreedor Prueba',
    description: 'Préstamo',
    amountCents: 1000000,
    currency: Currency.dop,
    dueDate: day,
    status: DebtStatus.settled,
    createdAt: created,
  );
  final debtPayment = DebtPayment(
    id: 7,
    debtId: 6,
    amountCents: 400000,
    date: day,
    note: 'x',
  );

  group('round trip', () {
    test(
      'AppUser',
      () => expectRoundTrip((AppUser m) => m.toMap(), AppUser.fromMap, user),
    );
    test(
      'CreditCard',
      () => expectRoundTrip(
        (CreditCard m) => m.toMap(),
        CreditCard.fromMap,
        card,
      ),
    );
    test(
      'Category',
      () => expectRoundTrip(
        (Category m) => m.toMap(),
        Category.fromMap,
        category,
      ),
    );
    test(
      'Expense',
      () => expectRoundTrip((Expense m) => m.toMap(), Expense.fromMap, expense),
    );
    test(
      'CardPayment',
      () => expectRoundTrip(
        (CardPayment m) => m.toMap(),
        CardPayment.fromMap,
        payment,
      ),
    );
    test(
      'Debt',
      () => expectRoundTrip((Debt m) => m.toMap(), Debt.fromMap, debt),
    );
    test('Debt without due date', () {
      final d = Debt(
        userId: 1,
        creditor: 'X',
        amountCents: 1,
        currency: Currency.usd,
        createdAt: created,
      );
      expectRoundTrip((Debt m) => m.toMap(), Debt.fromMap, d);
      expect(d.toMap().containsKey('id'), isFalse);
    });
    test(
      'DebtPayment',
      () => expectRoundTrip(
        (DebtPayment m) => m.toMap(),
        DebtPayment.fromMap,
        debtPayment,
      ),
    );
  });

  test('dates are stored without time, timestamps in full', () {
    final map = expense.copyWith(date: DateTime(2026, 1, 5, 23, 59)).toMap();
    expect(map['date'], '2026-01-05');
    expect(map['created_at'], '2026-10-21T14:30:05.000');
  });

  test('models persist and load through SQLite', () async {
    final appDb = await openTestDatabase();
    final db = appDb.db;
    final userId = await db.insert(
      'users',
      user.copyWith(id: null).toMap()..remove('id'),
    );
    final cardId = await db.insert(
      'cards',
      (CreditCard.fromMap({...card.toMap(), 'user_id': userId})).toMap()
        ..remove('id'),
    );
    final loaded = CreditCard.fromMap(
      (await db.query('cards', where: 'id = ?', whereArgs: [cardId])).single,
    );
    expect(loaded.last4, '0042');
    expect(loaded.brand, CardBrand.mastercard);
    expect(loaded.archived, isTrue);
    await appDb.close();
  });
}
