import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/test_db.dart';

/// Profile changes in AuthRepository. Emails are fictitious.
void main() {
  late AppDatabase db;
  late AuthRepository repo;
  late AppUser ana;

  setUp(() async {
    db = await openTestDatabase();
    SharedPreferences.setMockInitialValues({});
    repo = AuthRepository(
      db,
      testHasher,
      LoginThrottle(await SharedPreferences.getInstance()),
    );
    ana = await repo.register(
      firstName: 'Ana',
      lastName: 'Prueba',
      email: 'ana@example.com',
      password: 'abc12345',
    );
    await repo.register(
      firstName: 'Otra',
      lastName: 'Persona',
      email: 'otra@example.com',
      password: 'xyz98765',
    );
  });

  tearDown(() => db.close());

  group('change password', () {
    test('needs the current one; the new one gets a new salt', () async {
      final before = (await repo.getById(ana.id!))!;
      final after = await repo.changePassword(
        ana.id!,
        currentPassword: 'abc12345',
        newPassword: 'nueva2026',
      );
      expect(after.salt, isNot(before.salt));
      expect(after.passwordHash, isNot(before.passwordHash));
      expect(after.passwordHash, isNot(contains('nueva2026')));
      // Login: the new password works, the old one does not.
      expect((await repo.login('ana@example.com', 'nueva2026')).id, ana.id);
      expect(
        () => repo.login('ana@example.com', 'abc12345'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('a wrong current password changes nothing', () async {
      final before = (await repo.getById(ana.id!))!;
      await expectLater(
        repo.changePassword(
          ana.id!,
          currentPassword: 'equivocada1',
          newPassword: 'nueva2026',
        ),
        throwsA(isA<WrongPasswordException>()),
      );
      final after = (await repo.getById(ana.id!))!;
      expect(
        (after.salt, after.passwordHash),
        (before.salt, before.passwordHash),
      );
    });

    test('the new one follows the rules and must differ', () async {
      expect(
        () => repo.changePassword(
          ana.id!,
          currentPassword: 'abc12345',
          newPassword: 'corta1',
        ),
        throwsArgumentError,
      );
      expect(
        () => repo.changePassword(
          ana.id!,
          currentPassword: 'abc12345',
          newPassword: 'abc12345',
        ),
        throwsArgumentError,
      );
    });

    test('repeated wrong guesses are throttled like the login', () async {
      for (var i = 0; i < LoginThrottle.maxAttempts - 1; i++) {
        await expectLater(
          repo.changePassword(
            ana.id!,
            currentPassword:
                'mala$i'
                'xxxx',
            newPassword: 'nueva2026',
          ),
          throwsA(isA<WrongPasswordException>()),
        );
      }
      await expectLater(
        repo.changePassword(
          ana.id!,
          currentPassword: 'malaxxxx',
          newPassword: 'nueva2026',
        ),
        throwsA(isA<LockedOutException>()),
      );
      // Locked: even the right one waits.
      await expectLater(
        repo.changePassword(
          ana.id!,
          currentPassword: 'abc12345',
          newPassword: 'nueva2026',
        ),
        throwsA(isA<LockedOutException>()),
      );
    });
  });

  group('change email', () {
    test('needs the current password; stored normalized', () async {
      final u = await repo.changeEmail(
        ana.id!,
        currentPassword: 'abc12345',
        newEmail: ' Ana.Nueva@Example.com ',
      );
      expect(u.email, 'ana.nueva@example.com');
      expect(
        (await repo.login('ana.nueva@example.com', 'abc12345')).id,
        ana.id,
      );
    });

    test('an email that already exists is rejected (any case)', () async {
      await expectLater(
        repo.changeEmail(
          ana.id!,
          currentPassword: 'abc12345',
          newEmail: 'OTRA@example.com',
        ),
        throwsA(isA<EmailTakenException>()),
      );
      expect((await repo.getById(ana.id!))!.email, 'ana@example.com');
    });

    test('wrong password or invalid email', () async {
      expect(
        () => repo.changeEmail(
          ana.id!,
          currentPassword: 'equivocada1',
          newEmail: 'x@example.com',
        ),
        throwsA(isA<WrongPasswordException>()),
      );
      expect(
        () => repo.changeEmail(
          ana.id!,
          currentPassword: 'abc12345',
          newEmail: 'no-es-correo',
        ),
        throwsArgumentError,
      );
    });
  });

  test('update name trims and validates', () async {
    final u = await repo.updateName(ana.id!, '  María José ', ' Pérez ');
    expect((u.firstName, u.lastName), ('María José', 'Pérez'));
    expect(() => repo.updateName(ana.id!, ' ', 'X'), throwsArgumentError);
  });

  test('preferences: only the given ones change', () async {
    var u = await repo.updatePreferences(ana.id!, themeMode: ThemeMode.dark);
    expect(u.themeMode, ThemeMode.dark);
    expect(u.defaultCurrency, Currency.dop);
    u = await repo.updatePreferences(
      ana.id!,
      defaultCurrency: Currency.usd,
      notifyDaysBefore: 7,
      biometricEnabled: true,
    );
    expect(u.themeMode, ThemeMode.dark);
    expect(u.defaultCurrency, Currency.usd);
    expect(u.notifyDaysBefore, 7);
    expect(u.biometricEnabled, isTrue);
    expect(
      () => repo.updatePreferences(ana.id!, notifyDaysBefore: 31),
      throwsArgumentError,
    );
    expect(
      () => repo.updatePreferences(ana.id!, notifyDaysBefore: -1),
      throwsArgumentError,
    );
  });

  test('changes only touch the given user', () async {
    final otra = await repo.login('otra@example.com', 'xyz98765');
    await repo.updateName(ana.id!, 'Cambiada', 'Nombre');
    await repo.updatePreferences(ana.id!, themeMode: ThemeMode.dark);
    final o = (await repo.getById(otra.id!))!;
    expect((o.firstName, o.themeMode), ('Otra', ThemeMode.system));
  });
}
