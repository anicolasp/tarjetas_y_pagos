import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/language.dart';
import 'package:tarjetas_y_pagos/core/validators.dart' show nameMaxLength;
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/test_db.dart';

/// Signing in with Google (#37) at the repository: Google's id (`sub`) and
/// the email are kept, never a token. Fictitious accounts.
void main() {
  late AppDatabase db;
  late AuthRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    SharedPreferences.setMockInitialValues({});
    repo = AuthRepository(
      db,
      testHasher,
      LoginThrottle(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() => db.close());

  Future<({AppUser user, bool created})> google({
    String sub = 'g-ana',
    String email = 'ana@example.com',
    String? name = 'Ana María Prueba',
  }) => repo.loginWithGoogle(
    sub: sub,
    email: email,
    name: name,
    language: AppLanguage.en,
  );

  Future<void> registerAna() => repo.register(
    firstName: 'Ana',
    lastName: 'Prueba',
    email: 'ana@example.com',
    password: 'abc12345',
  );

  test('a new Google account creates a user without a password', () async {
    final (:user, :created) = await google();
    expect(created, isTrue);
    expect(user.firstName, 'Ana');
    expect(user.lastName, 'María Prueba');
    expect(user.email, 'ana@example.com');
    expect(user.googleSub, 'g-ana');
    expect(user.hasPassword, isFalse);
    expect(user.language, AppLanguage.en);
  });

  test('the same Google account signs in to the same user', () async {
    final first = await google();
    final again = await google(email: 'otro@example.com');
    expect(again.created, isFalse);
    expect(again.user.id, first.user.id);
    expect(await db.db.query('users'), hasLength(1));
  });

  test('a long name is cut to what the name rules accept, whole '
      'characters only', () async {
    final (:user, created: _) = await google(name: '😀' * 40);
    expect(user.firstName.length, lessThanOrEqualTo(nameMaxLength));
    expect(user.firstName, '😀' * 25);
  });

  test('without a name, the part of the email before "@"', () async {
    final (:user, created: _) = await google(name: null);
    expect(user.firstName, 'ana');
    expect(user.lastName, '');
  });

  test('no token or secret is stored, only the id and email', () async {
    await google();
    final columns = (await db.db.rawQuery('PRAGMA table_info(users)'))
        .map((c) => c['name'] as String);
    expect(columns.where((c) => c.contains('token')), isEmpty);
    final row = (await db.db.query('users')).single;
    expect(row['google_sub'], 'g-ana');
    expect(row['password_hash'], '');
    expect(row['salt'], '');
  });

  group('an email that already has an account', () {
    test('asks for its password to link', () async {
      await registerAna();
      await expectLater(google(), throwsA(isA<GoogleLinkNeededException>()));
      expect(await db.db.query('users'), hasLength(1));
    });

    test('a wrong password does not link', () async {
      await registerAna();
      await expectLater(
        repo.linkGoogle(
          email: 'ana@example.com',
          password: 'mala1234',
          sub: 'g-ana',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect((await db.db.query('users')).single['google_sub'], isNull);
    });

    test('the right one links; then Google signs in directly', () async {
      await registerAna();
      final linked = await repo.linkGoogle(
        email: 'ana@example.com',
        password: 'abc12345',
        sub: 'g-ana',
      );
      expect(linked.googleSub, 'g-ana');
      expect(linked.hasPassword, isTrue);
      final (:user, :created) = await google();
      expect(created, isFalse);
      expect(user.id, linked.id);
    });

    test('an account linked to another Google account is not '
        're-linked (that one would be cut off)', () async {
      await registerAna();
      await repo.linkGoogle(
        email: 'ana@example.com',
        password: 'abc12345',
        sub: 'g-old',
      );
      await expectLater(
        repo.linkGoogle(
          email: 'ana@example.com',
          password: 'abc12345',
          sub: 'g-new',
        ),
        throwsA(isA<GoogleAlreadyLinkedException>()),
      );
      expect((await db.db.query('users')).single['google_sub'], 'g-old');
    });

    test('a Google account linked to someone else is refused', () async {
      await google(sub: 'g-1', email: 'luis@example.com');
      await registerAna();
      await expectLater(
        repo.linkGoogle(
          email: 'ana@example.com',
          password: 'abc12345',
          sub: 'g-1',
        ),
        throwsA(isA<GoogleAccountTakenException>()),
      );
    });
  });

  group('an account created with Google', () {
    test('a password login says it signs in with Google, without '
        'counting toward the lockout', () async {
      await google();
      for (var i = 0; i < 8; i++) {
        await expectLater(
          repo.login('ana@example.com', 'abc12345'),
          throwsA(isA<GoogleOnlyAccountException>()),
        );
      }
    });

    test('sets a first password, then signs in with it too', () async {
      final (:user, created: _) = await google();
      final updated = await repo.setPassword(user.id!, 'nueva2026');
      expect(updated.hasPassword, isTrue);
      expect(updated.googleSub, 'g-ana');
      expect((await repo.login('ana@example.com', 'nueva2026')).id, user.id);
      // Changing it from then on needs the current one.
      await expectLater(
        repo.setPassword(user.id!, 'otra2026a'),
        throwsA(isA<StateError>()),
      );
    });

    test('recovery says it signs in with Google', () async {
      await google();
      await expectLater(
        repo.securityQuestionFor('ana@example.com'),
        throwsA(isA<GoogleOnlyAccountException>()),
      );
    });
  });

  group('unlinking Google', () {
    test('needs the password', () async {
      await registerAna();
      final linked = await repo.linkGoogle(
        email: 'ana@example.com',
        password: 'abc12345',
        sub: 'g-ana',
      );
      await expectLater(
        repo.unlinkGoogle(linked.id!, currentPassword: 'mala1234'),
        throwsA(isA<WrongPasswordException>()),
      );
      final unlinked = await repo.unlinkGoogle(
        linked.id!,
        currentPassword: 'abc12345',
      );
      expect(unlinked.googleSub, isNull);
      expect((await repo.login('ana@example.com', 'abc12345')).id, linked.id);
    });

    test('is impossible without a password: nothing can confirm it', () async {
      final (:user, created: _) = await google();
      await expectLater(
        repo.unlinkGoogle(user.id!, currentPassword: ''),
        throwsA(isA<WrongPasswordException>()),
      );
      expect((await repo.getById(user.id!))!.googleSub, 'g-ana');
    });
  });
}
