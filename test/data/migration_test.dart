import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';

/// Upgrading a real v1 database (with data) to the current schema.
void main() {
  late Directory dir;
  late String path;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tyc_migration');
    path = '${dir.path}/app.db';
  });
  tearDown(() => dir.delete(recursive: true));

  Future<AppDatabase> openAt(int? version) => AppDatabase.open(
    factory: databaseFactoryFfiNoIsolate,
    path: path,
    targetVersion: version,
  );

  test('v1 → v2 keeps data and adds the new columns with defaults', () async {
    final v1 = await openAt(1);
    final userId = await v1.db.insert('users', {
      'first_name': 'Ana',
      'last_name': 'Prueba',
      'email': 'ana@example.com',
      'password_hash': 'h',
      'salt': 's',
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    final cardId = await v1.db.insert('cards', {
      'user_id': userId,
      'alias': 'Vieja',
      'bank': 'Banco Prueba',
      'brand': 'visa',
      'last4': '1234',
      'cut_day': 5,
      'credit_limit_cents': 5000000,
      'currency': 'DOP',
      'color': 1,
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    final category = (await v1.db.query('categories', limit: 1)).single['id'];
    await v1.db.insert('expenses', {
      'user_id': userId,
      'card_id': cardId,
      'category_id': category,
      'merchant': 'Súper',
      'amount_cents': 250000,
      'currency': 'DOP',
      'date': '2026-01-10',
      'created_at': '2026-01-10T00:00:00.000Z',
    });
    expect(await v1.db.getVersion(), 1);
    await v1.close();

    final v2 = await openAt(null);
    expect(await v2.db.getVersion(), AppDatabase.version);

    final card = CreditCard.fromMap((await v2.db.query('cards')).single);
    expect(card.alias, 'Vieja');
    expect(card.dualCurrency, isFalse);
    expect(card.secondaryLimitCents, 0);
    expect(card.currencies, [Currency.dop]);

    final expense = Expense.fromMap((await v2.db.query('expenses')).single);
    expect(expense.amountCents, 250000);
    expect(expense.wasConverted, isFalse);
    expect(expense.exchangeRateMicros, isNull);
    await v2.close();
  });

  test('v2 enforces the new checks', () async {
    final db = await openAt(null);
    final userId = await db.db.insert('users', {
      'first_name': 'Ana',
      'last_name': 'Prueba',
      'email': 'ana@example.com',
      'password_hash': 'h',
      'salt': 's',
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    expect(
      () => db.db.insert('cards', {
        'user_id': userId,
        'alias': 'X',
        'bank': 'B',
        'brand': 'visa',
        'last4': '1234',
        'cut_day': 5,
        'currency': 'DOP',
        'secondary_limit_cents': -1,
        'color': 1,
        'created_at': '2026-01-01T00:00:00.000Z',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await db.close();
  });

  test('v2 → v3 keeps users in Spanish', () async {
    final v2 = await openAt(2);
    final userId = await v2.db.insert('users', {
      'first_name': 'Ana',
      'last_name': 'Prueba',
      'email': 'ana@example.com',
      'password_hash': 'h',
      'salt': 's',
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    await v2.close();

    final v3 = await openAt(null);
    final user = (await v3.db.query('users')).single;
    expect(user['id'], userId);
    expect(user['language'], 'es');
    await v3.db.update('users', {'language': 'fr'});
    expect((await v3.db.query('users')).single['language'], 'fr');
    await v3.close();
  });
}
