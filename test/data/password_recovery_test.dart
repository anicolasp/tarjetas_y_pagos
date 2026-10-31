import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/security_question.dart';
import 'package:tarjetas_y_pagos/core/validators.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/test_db.dart';

/// Password recovery with a security question (#27). Fictitious data.
void main() {
  late AppDatabase db;
  late AuthRepository repo;
  late AppUser ana;

  const city = PresetQuestion(SecurityQuestionPreset.birthCity);

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
      securityQuestion: city,
      securityAnswer: 'Santo Domingo',
    );
  });

  tearDown(() => db.close());

  Future<Map<String, Object?>> row(String email) async => (await db.db.query(
    'users',
    where: 'email = ?',
    whereArgs: [email],
  )).single;

  test('answers are compared without case, accents or extra spaces', () {
    expect(normalizeSecurityAnswer('  Santo   Domingo '), 'santo domingo');
    expect(normalizeSecurityAnswer('SÁNTO DOMÍNGO'), 'santo domingo');
    expect(normalizeSecurityAnswer('Peña'), 'pena');
  });

  test('the answer is stored only as a salted hash', () async {
    final r = await row('ana@example.com');
    expect(r['security_question'], 'preset:birthCity');
    expect(r['security_answer_hash'], isNotNull);
    expect(r['security_salt'], isNot(r['salt']));
    final everything = r.values.join(' ').toLowerCase();
    expect(everything, isNot(contains('santo')));
    expect(ana.securityQuestion, city);
  });

  test('question for an email', () async {
    expect(await repo.securityQuestionFor(' ANA@example.com '), city);
    expect(
      () => repo.securityQuestionFor('nadie@example.com'),
      throwsA(isA<AccountNotFoundException>()),
    );
  });

  test(
    'right answer: new password, new salt; the old one stops working',
    () async {
      final before = await row('ana@example.com');
      await repo.resetPasswordWithAnswer(
        email: 'ana@example.com',
        answer: 'santo domingo',
        newPassword: 'nueva2026',
      );
      final after = await row('ana@example.com');
      expect(after['salt'], isNot(before['salt']));
      expect(
        () => repo.login('ana@example.com', 'abc12345'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect((await repo.login('ana@example.com', 'nueva2026')).id, ana.id);
      // Same question and answer after the reset.
      expect(after['security_answer_hash'], before['security_answer_hash']);
    },
  );

  test('wrong answers: progressive lockout shared with the login', () async {
    for (var i = 0; i < 4; i++) {
      await expectLater(
        repo.checkSecurityAnswer('ana@example.com', 'Santiago'),
        throwsA(isA<WrongAnswerException>()),
      );
    }
    await expectLater(
      repo.checkSecurityAnswer('ana@example.com', 'Santiago'),
      throwsA(isA<LockedOutException>()),
    );
    // Locked even with the right answer, and for the login too.
    await expectLater(
      repo.checkSecurityAnswer('ana@example.com', 'Santo Domingo'),
      throwsA(isA<LockedOutException>()),
    );
    await expectLater(
      repo.login('ana@example.com', 'abc12345'),
      throwsA(isA<LockedOutException>()),
    );
  });

  test('the new password follows the rules and must change', () async {
    await expectLater(
      repo.resetPasswordWithAnswer(
        email: 'ana@example.com',
        answer: 'Santo Domingo',
        newPassword: 'corta',
      ),
      throwsA(
        isA<FieldErrorException>().having(
          (e) => e.error,
          'error',
          FieldError.passwordTooShort,
        ),
      ),
    );
    await expectLater(
      repo.resetPasswordWithAnswer(
        email: 'ana@example.com',
        answer: 'Santo Domingo',
        newPassword: 'abc12345',
      ),
      throwsA(
        isA<FieldErrorException>().having(
          (e) => e.error,
          'error',
          FieldError.samePassword,
        ),
      ),
    );
  });

  test(
    'accounts without a question cannot recover; they can set one',
    () async {
      final old = await repo.register(
        firstName: 'Luis',
        lastName: 'Ficticio',
        email: 'luis@example.com',
        password: 'abc12345',
      );
      expect(old.hasSecurityQuestion, isFalse);
      await expectLater(
        repo.securityQuestionFor('luis@example.com'),
        throwsA(isA<NoSecurityQuestionException>()),
      );
      await expectLater(
        repo.resetPasswordWithAnswer(
          email: 'luis@example.com',
          answer: 'algo',
          newPassword: 'nueva2026',
        ),
        throwsA(isA<NoSecurityQuestionException>()),
      );

      // Setting one needs the current password.
      await expectLater(
        repo.setSecurityQuestion(
          old.id!,
          currentPassword: 'equivocada1',
          question: const CustomQuestion('¿Color favorito?'),
          answer: 'Verde',
        ),
        throwsA(isA<WrongPasswordException>()),
      );
      final updated = await repo.setSecurityQuestion(
        old.id!,
        currentPassword: 'abc12345',
        question: const CustomQuestion('¿Color favorito?'),
        answer: 'Verde',
      );
      expect(
        updated.securityQuestion,
        const CustomQuestion('¿Color favorito?'),
      );
      await repo.checkSecurityAnswer('luis@example.com', 'verde');
    },
  );

  test('question and answer are validated', () {
    expect(
      () => repo.setSecurityQuestion(
        ana.id!,
        currentPassword: 'abc12345',
        question: city,
        answer: ' a ',
      ),
      throwsA(isA<FieldErrorException>()),
    );
    expect(
      () => repo.setSecurityQuestion(
        ana.id!,
        currentPassword: 'abc12345',
        question: const CustomQuestion('  '),
        answer: 'Verde',
      ),
      throwsA(isA<FieldErrorException>()),
    );
  });
}
