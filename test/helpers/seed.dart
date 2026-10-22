import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/data/repositories/cards_repository.dart';
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
