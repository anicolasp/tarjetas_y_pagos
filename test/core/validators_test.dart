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
      expect(validateEmail(null), 'Escribe tu correo');
      expect(validateEmail('  '), 'Escribe tu correo');
      for (final e in ['ana', 'ana@', '@b.co', 'a b@c.do', 'a@b']) {
        expect(validateEmail(e), 'Correo no válido', reason: e);
      }
    });
  });

  group('validatePassword', () {
    test('needs 8+ chars with letters and digits', () {
      expect(validatePassword('abc12345'), isNull);
      expect(validatePassword('Ñandú2026'), isNull);
      expect(validatePassword(''), 'Escribe tu contraseña');
      expect(validatePassword('abc1234'), 'Mínimo 8 caracteres');
      expect(validatePassword('abcdefgh'), 'Debe tener letras y números');
      expect(validatePassword('12345678'), 'Debe tener letras y números');
      expect(validatePassword('a1' * 65), 'Máximo 128 caracteres');
    });
  });

  test('validatePasswordConfirmation', () {
    expect(validatePasswordConfirmation('abc12345', 'abc12345'), isNull);
    expect(
      validatePasswordConfirmation('', 'abc12345'),
      'Confirma tu contraseña',
    );
    expect(
      validatePasswordConfirmation('abc12346', 'abc12345'),
      'Las contraseñas no coinciden',
    );
  });

  test('validateName', () {
    expect(validateName('Ana', field: 'nombre'), isNull);
    expect(validateName('  ', field: 'nombre'), 'Escribe tu nombre');
    expect(validateName('x' * 51, field: 'apellido'), 'Máximo 50 caracteres');
  });
}
