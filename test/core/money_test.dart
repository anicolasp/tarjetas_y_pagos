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

  group('rateMicrosFor', () {
    test('USD → DOP uses the rate, same currency is 1', () {
      expect(rateMicrosFor(Currency.usd, Currency.dop, usdToDop), usdToDop);
      expect(rateMicrosFor(Currency.dop, Currency.dop, usdToDop), rateScale);
    });

    test('DOP → USD uses the inverse', () {
      final inverse = rateMicrosFor(Currency.dop, Currency.usd, usdToDop);
      expect(inverse, 16284); // 1 / 61.409228 = 0.016284…
      // RD$ 6,140.92 ≈ US$ 100.00
      expect(convertCents(614092, inverse), 10000);
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
}
