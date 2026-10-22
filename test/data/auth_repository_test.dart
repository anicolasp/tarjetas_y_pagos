import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';
import 'package:tarjetas_y_pagos/services/password_hasher.dart';

import '../helpers/fakes.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late AuthRepository repo;

  AuthRepository repoWith(PasswordHasher hasher, SharedPreferences prefs) =>
      AuthRepository(db, hasher, LoginThrottle(prefs));

  setUp(() async {
    db = await openTestDatabase();
    SharedPreferences.setMockInitialValues({});
    repo = repoWith(testHasher, await SharedPreferences.getInstance());
  });

  tearDown(() => db.close());

  Future<void> registerAna() => repo.register(
    firstName: ' Ana ',
    lastName: 'Prueba',
    email: ' Ana@Example.com ',
    password: 'abc12345',
  );

  test('register stores a normalized user with a hashed password', () async {
    final user = await repo.register(
      firstName: ' Ana ',
      lastName: 'Prueba',
      email: ' Ana@Example.com ',
      password: 'abc12345',
    );
    expect(user.id, isNotNull);
    expect(user.firstName, 'Ana');
    expect(user.email, 'ana@example.com');

    final row = (await db.db.query('users')).single;
    expect(row['password_hash'], isNot(contains('abc12345')));
    expect(row['password_hash'] as String, startsWith('pbkdf2-sha256'));
    expect(row['salt'], isNotEmpty);
  });

  test('register rejects a duplicate email, ignoring case', () async {
    await registerAna();
    expect(
      () => repo.register(
        firstName: 'Otra',
        lastName: 'Persona',
        email: 'ANA@example.com',
        password: 'xyz98765',
      ),
      throwsA(isA<EmailTakenException>()),
    );
  });

  test('register validates its input', () async {
    expect(
      () => repo.register(
        firstName: 'Ana',
        lastName: 'Prueba',
        email: 'ana@example.com',
        password: 'corta',
      ),
      throwsArgumentError,
    );
    expect(await db.db.query('users'), isEmpty);
  });

  test('login with the right password', () async {
    await registerAna();
    final user = await repo.login('ANA@example.com ', 'abc12345');
    expect(user.firstName, 'Ana');
  });

  test(
    'login with a wrong password or unknown email fails the same way',
    () async {
      await registerAna();
      expect(
        () => repo.login('ana@example.com', 'abc12346'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(
        () => repo.login('nadie@example.com', 'abc12345'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    },
  );

  test('5 wrong passwords lock the email, even the right one', () async {
    await registerAna();
    for (var i = 0; i < 4; i++) {
      await expectLater(
        repo.login('ana@example.com', 'mala1234'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    }
    await expectLater(
      repo.login('ana@example.com', 'mala1234'),
      throwsA(isA<LockedOutException>()),
    );
    await expectLater(
      repo.login('ana@example.com', 'abc12345'),
      throwsA(isA<LockedOutException>()),
    );
  });

  test('login re-hashes when the iteration count changed', () async {
    final prefs = await SharedPreferences.getInstance();
    const old = PasswordHasher(iterations: 500, useIsolate: false);
    await repoWith(old, prefs).register(
      firstName: 'Ana',
      lastName: 'Prueba',
      email: 'ana@example.com',
      password: 'abc12345',
    );
    final before = (await db.db.query('users')).single;
    expect(
      before['password_hash'] as String,
      startsWith(r'pbkdf2-sha256$500$'),
    );

    await repo.login('ana@example.com', 'abc12345');
    final after = (await db.db.query('users')).single;
    expect(
      after['password_hash'] as String,
      startsWith(r'pbkdf2-sha256$1000$'),
    );
    expect(after['salt'], isNot(before['salt']));
    expect(
      (await repo.login('ana@example.com', 'abc12345')).email,
      'ana@example.com',
    );
  });

  test('getById', () async {
    await registerAna();
    final id = (await db.db.query('users')).single['id'] as int;
    expect((await repo.getById(id))?.email, 'ana@example.com');
    expect(await repo.getById(999), isNull);
  });
}
