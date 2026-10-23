import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/card_detection.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';

/// Public test numbers only (never real cards).
void main() {
  group('luhnValid', () {
    for (final n in [
      '4111111111111111',
      '5555555555554444',
      '378282246310005',
      '2221000000000009',
      '4222222222222',
    ]) {
      test('valid: $n', () => expect(luhnValid(n), isTrue));
    }
    for (final n in ['4111111111111112', '1234567812345678', '', '41111a11']) {
      test('invalid: "$n"', () => expect(luhnValid(n), isFalse));
    }
  });

  group('brandFor (10 test BINs)', () {
    const cases = {
      '4111111111111111': CardBrand.visa,
      '4012888888881881': CardBrand.visa,
      '5105105105105100': CardBrand.mastercard,
      '5555555555554444': CardBrand.mastercard,
      '2221000000000009': CardBrand.mastercard,
      '2720990000000000': CardBrand.mastercard,
      '378282246310005': CardBrand.amex,
      '341111111111111': CardBrand.amex,
      '6011111111111117': CardBrand.other, // Discover
      '2220990000000000': CardBrand.other, // just below 2221
    };
    for (final MapEntry(key: n, value: brand) in cases.entries) {
      test('$n → ${brand.name}', () => expect(brandFor(n), brand));
    }
    test('2721 is not Mastercard', () {
      expect(brandFor('2721000000000000'), CardBrand.other);
    });
    test('56 is not Mastercard', () {
      expect(brandFor('5600000000000000'), CardBrand.other);
    });
  });

  group('bankIn', () {
    test('any case, with or without accents', () {
      expect(bankIn('BANCO POPULAR'), 'Banco Popular');
      expect(bankIn('banco popular dominicano'), 'Banco Popular');
      expect(bankIn('Banco López de Haro'), 'Banco López de Haro');
      expect(bankIn('BANCO LOPEZ DE HARO'), 'Banco López de Haro');
      expect(bankIn('ASOCIACIÓN CIBAO'), 'Asociación Cibao');
      expect(bankIn('bhd león'), 'BHD');
      expect(bankIn('Scotia'), 'Scotiabank');
      expect(bankIn('BanReservas'), 'Banreservas');
    });

    test('the longest alias wins: APAP over Banco Popular', () {
      expect(bankIn('Asociación Popular de Ahorros y Préstamos'), 'APAP');
    });

    test('whole words only', () {
      expect(bankIn('BDIX'), isNull);
      expect(bankIn('populares'), isNull);
      expect(bankIn('VISA PLATINUM'), isNull);
    });
  });

  group('detectCard', () {
    test('number with spaces, brand and bank', () {
      final d = detectCard(
        'BANCO POPULAR\n4111 1111 1111 1111\nVALID THRU 12/28\nANA PEREZ',
      );
      expect(d.last4, '1111');
      expect(d.brand, CardBrand.visa);
      expect(d.bank, 'Banco Popular');
    });

    test('number without spaces or with dashes', () {
      expect(detectCard('5555555555554444').last4, '4444');
      expect(detectCard('3782-822463-10005').last4, '0005');
      expect(detectCard('3782-822463-10005').brand, CardBrand.amex);
    });

    test('nearby digits are not glued to the number', () {
      final d = detectCard('4111 1111 1111 1111 0425');
      expect(d.last4, '1111');
    });

    test('the first Luhn-valid number wins; invalid ones are skipped', () {
      final d = detectCard(
        'Ref 1234 5678 1234 5678\n5105 1051 0510 5100\n4111 1111 1111 1111',
      );
      expect(d.last4, '5100');
      expect(d.brand, CardBrand.mastercard);
    });

    test('only an invalid number: no last 4 and no brand', () {
      final d = detectCard('4111 1111 1111 1112 BHD');
      expect(d.last4, isNull);
      expect(d.brand, isNull);
      expect(d.bank, 'BHD');
      expect(d.isEmpty, isFalse);
    });

    test('nothing usable', () {
      expect(detectCard('').isEmpty, isTrue);
      expect(detectCard('VALID THRU 12/28 ANA PEREZ').isEmpty, isTrue);
    });
  });
}
