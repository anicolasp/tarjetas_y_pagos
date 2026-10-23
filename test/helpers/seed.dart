import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/data/repositories/cards_repository.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import 'fakes.dart';

/// Registers a user with fictitious data and returns it.
Future<AppUser> seedUser(
  AppDatabase db, {
  String firstName = 'María José',
  String lastName = 'Pérez Rodríguez',
  String email = 'maria.jose@example.com',
}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = AuthRepository(
    db,
    testHasher,
    LoginThrottle(await SharedPreferences.getInstance()),
  );
  return repo.register(
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: 'abc12345',
  );
}

Future<CreditCard> seedCard(
  AppDatabase db,
  int userId, {
  String alias = 'Tarjeta',
  int cutDay = 15,
  int paymentDays = 20,
  int limitCents = 0,
  Currency currency = Currency.dop,
  String last4 = '1234',
}) => CardsRepository(db).create(
  CreditCard(
    userId: userId,
    alias: alias,
    bank: 'Banco Prueba',
    brand: CardBrand.visa,
    last4: last4,
    cutDay: cutDay,
    paymentDays: paymentDays,
    creditLimitCents: limitCents,
    currency: currency,
    color: 0xFF0F766E,
    createdAt: DateTime(2026),
  ),
);

/// An expense on [cardId] in the base category [categoryName]. Defaults to
/// RD$ 1,000.00 on 20 Oct 2026 (repository "today" is 22 Oct 2026).
Future<Expense> seedExpense(
  AppDatabase db,
  int userId,
  int cardId,
  String categoryName,
  String merchant, {
  int cents = 100000,
  DateTime? date,
  Currency currency = Currency.dop,
}) async {
  final repo = ExpensesRepository(db, clock: () => DateTime(2026, 10, 22, 10));
  final category = (await repo.categories(userId))
      .firstWhere((c) => c.name == categoryName);
  return repo.create(
    Expense(
      userId: userId,
      cardId: cardId,
      categoryId: category.id!,
      merchant: merchant,
      amountCents: cents,
      currency: currency,
      date: date ?? DateTime(2026, 10, 20),
      createdAt: DateTime(2026, 10, 22),
    ),
  );
}
