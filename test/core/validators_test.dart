import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/validators.dart';

void main() {
  test('normalizeEmail trims and lowercases', () {
    expect(
      normalizeEmail('  Ana.Prueba@Example.COM '),
      'ana.prueba@example.com',
    );
  });

  group('validateEmail', () {
    test('accepts valid emails', () {
      for (final e in ['a@b.co', 'ana.prueba+x@example.com', ' a@b.do ']) {
        expect(validateEmail(e), isNull, reason: e);
      }
    });

    test('rejects invalid emails', () {
      expect(validateEmail(null), FieldError.emailRequired);
      expect(validateEmail('  '), FieldError.emailRequired);
      for (final e in ['ana', 'ana@', '@b.co', 'a b@c.do', 'a@b']) {
        expect(validateEmail(e), FieldError.emailInvalid, reason: e);
      }
    });
  });

  group('validatePassword', () {
    test('needs 8+ chars with letters and digits', () {
      expect(validatePassword('abc12345'), isNull);
      expect(validatePassword('Ñandú2026'), isNull);
      expect(validatePassword(''), FieldError.passwordRequired);
      expect(validatePassword('abc1234'), FieldError.passwordTooShort);
      expect(validatePassword('abcdefgh'), FieldError.passwordLettersDigits);
      expect(validatePassword('12345678'), FieldError.passwordLettersDigits);
      expect(validatePassword('a1' * 65), FieldError.passwordTooLong);
    });
  });

  test('validatePasswordConfirmation', () {
    expect(validatePasswordConfirmation('abc12345', 'abc12345'), isNull);
    expect(
      validatePasswordConfirmation('', 'abc12345'),
      FieldError.confirmRequired,
    );
    expect(
      validatePasswordConfirmation('abc12346', 'abc12345'),
      FieldError.passwordMismatch,
    );
  });

  test('validateName', () {
    expect(validateName('Ana', field: NameField.first), isNull);
    expect(
      validateName('  ', field: NameField.first),
      FieldError.firstNameRequired,
    );
    expect(
      validateName('  ', field: NameField.last),
      FieldError.lastNameRequired,
    );
    expect(
      validateName('x' * 51, field: NameField.last),
      FieldError.nameTooLong,
    );
  });
}
