import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/money.dart';

void main() {
  const usdToDop = 61409228; // 61.409228

  group('convertCents', () {
    test('US\$ 40.00 at 61.409228 → RD\$ 2,456.37', () {
      expect(convertCents(4000, usdToDop), 245637);
    });

    test('rounds half up to the cent', () {
      // 1 cent x 1.5 = 1.5 cents → 2.
      expect(convertCents(1, 1500000), 2);
      expect(convertCents(1, 1499999), 1);
    });

    test('identity rate keeps the amount', () {
      expect(convertCents(123456, rateScale), 123456);
    });

    test('large amounts do not overflow', () {
      // RD$ 100 million in cents at 61.4 → no overflow in 64-bit ints.
      expect(convertCents(10000000000, usdToDop), 614092280000);
    });
  });

  group('convertBetween', () {
    test('same currency keeps the amount', () {
      expect(convertBetween(123, Currency.dop, Currency.dop, usdToDop), 123);
    });

    test('US\$ → RD\$ multiplies', () {
      expect(
        convertBetween(4000, Currency.usd, Currency.dop, usdToDop),
        245637,
      );
    });

    test('RD\$ → US\$ divides exactly', () {
      // RD$ 6,140.92 / 61.409228 = US$ 100.00
      expect(
        convertBetween(614092, Currency.dop, Currency.usd, usdToDop),
        10000,
      );
      // RD$ 1,000,000.00 → US$ 16,284.20 (an inverse rate in micros would
      // give 16,284.00).
      expect(
        convertBetween(100000000, Currency.dop, Currency.usd, usdToDop),
        1628420,
      );
    });
  });

  group('parseRateMicros / formatRate', () {
    test('parses dot and comma decimals', () {
      expect(parseRateMicros('61.409228'), 61409228);
      expect(parseRateMicros('61,5'), 61500000);
      expect(parseRateMicros(' 60 '), 60000000);
    });

    test('rejects invalid or zero rates', () {
      for (final bad in ['', 'abc', '0', '0.000000', '-60', '1.1234567']) {
        expect(parseRateMicros(bad), isNull, reason: bad);
      }
    });

    test('formats with at least 2 decimals', () {
      expect(formatRate(61409228), '61.409228');
      expect(formatRate(61500000), '61.50');
      expect(formatRate(60000000), '60.00');
    });
  });

  test('huge amounts convert without 64-bit overflow', () {
    // RD$ 9,999,999,999.99 → US$ at 61.409228, both directions.
    final usd = convertBetween(
      999999999999,
      Currency.dop,
      Currency.usd,
      usdToDop,
    );
    expect(usd, 16284197548); // checked with Python Decimal
    expect(
      convertBetween(usd, Currency.usd, Currency.dop, usdToDop),
      1000000000022,
    );
  });
}
