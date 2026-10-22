import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarjetas_y_pagos/data/database.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase appDb;
  late Database db;

  setUp(() async {
    appDb = await openTestDatabase();
    db = appDb.db;
  });

  tearDown(() => appDb.close());

  Future<int> insertUser() => db.insert('users', {
    'first_name': 'Ana',
    'last_name': 'Prueba',
    'email': 'ana@example.com',
    'password_hash': 'h',
    'salt': 's',
    'created_at': DateTime(2026).toIso8601String(),
  });

  Map<String, Object?> card(int userId, {String last4 = '1234'}) => {
    'user_id': userId,
    'alias': 'Principal',
    'bank': 'Banco Prueba',
    'brand': 'visa',
    'last4': last4,
    'cut_day': 15,
    'currency': 'DOP',
    'color': 0xFF0F766E,
    'created_at': DateTime(2026).toIso8601String(),
  };

  test('creates the 7 tables', () async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    expect(rows.map((r) => r['name']).toSet(), {
      'users',
      'cards',
      'categories',
      'expenses',
      'card_payments',
      'debts',
      'debt_payments',
    });
  });

  test('seeds the 13 base categories without owner', () async {
    final rows = await db.query('categories');
    expect(rows, hasLength(13));
    expect(rows.every((r) => r['user_id'] == null), isTrue);
    expect(
      rows.map((r) => r['name']),
      containsAll(['Supermercado', 'Combustible', 'Luz', 'Otros']),
    );
    expect(baseCategories, hasLength(13));
  });

  test('enables foreign keys', () async {
    final rows = await db.rawQuery('PRAGMA foreign_keys');
    expect(rows.single.values.single, 1);
    expect(
      () => db.insert('cards', card(999)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('email is unique regardless of case', () async {
    await insertUser();
    expect(
      () => db.insert('users', {
        'first_name': 'B',
        'last_name': 'C',
        'email': 'ANA@example.com',
        'password_hash': 'h',
        'salt': 's',
        'created_at': DateTime(2026).toIso8601String(),
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('cards only accept exactly 4 digits', () async {
    final userId = await insertUser();
    await db.insert('cards', card(userId));
    for (final bad in ['123', '12345', '12a4', '4111111111111111']) {
      expect(
        () => db.insert('cards', card(userId, last4: bad)),
        throwsA(isA<DatabaseException>()),
        reason: bad,
      );
    }
  });

  test('deleting a user cascades to their cards', () async {
    final userId = await insertUser();
    await db.insert('cards', card(userId));
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    expect(await db.query('cards'), isEmpty);
  });

  test('an expense cannot use another user\'s card', () async {
    final owner = await insertUser();
    final other = await db.insert('users', {
      'first_name': 'Otro',
      'last_name': 'Usuario',
      'email': 'otro@example.com',
      'password_hash': 'h',
      'salt': 's',
      'created_at': DateTime(2026).toIso8601String(),
    });
    final cardId = await db.insert('cards', card(owner));
    final category = (await db.query('categories', limit: 1)).single['id'];
    Map<String, Object?> expense(int userId) => {
      'user_id': userId,
      'card_id': cardId,
      'category_id': category,
      'merchant': 'Comercio',
      'amount_cents': 100,
      'currency': 'DOP',
      'date': '2026-10-01',
      'created_at': DateTime(2026).toIso8601String(),
    };

    await db.insert('expenses', expense(owner));
    expect(
      () => db.insert('expenses', expense(other)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('category names are unique per owner', () async {
    final userId = await insertUser();
    Map<String, Object?> cat(int? owner, String name) => {
      'user_id': owner,
      'name': name,
      'icon': 'pets',
      'color': 1,
    };

    expect(
      () => db.insert('categories', cat(null, 'supermercado')),
      throwsA(isA<DatabaseException>()),
    );
    await db.insert('categories', cat(userId, 'Mascotas'));
    expect(
      () => db.insert('categories', cat(userId, 'MASCOTAS')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('version matches the number of migrations', () async {
    expect(await db.getVersion(), AppDatabase.version);
  });
}
