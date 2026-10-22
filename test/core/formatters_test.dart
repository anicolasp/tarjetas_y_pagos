import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';

void main() {
  setUpAll(() => initializeDateFormatting(appLocale));

  group('formatMoney', () {
    test('formats pesos and dollars', () {
      expect(formatMoney(125000, Currency.dop), 'RD\$ 1,250.00');
      expect(formatMoney(125000, Currency.usd), 'US\$ 1,250.00');
    });

    test('handles zero, cents and large amounts', () {
      expect(formatMoney(0, Currency.dop), 'RD\$ 0.00');
      expect(formatMoney(5, Currency.dop), 'RD\$ 0.05');
      expect(formatMoney(123456789, Currency.usd), 'US\$ 1,234,567.89');
    });

    test('puts the sign before the symbol', () {
      expect(formatMoney(-125050, Currency.dop), '-RD\$ 1,250.50');
    });
  });

  test('Currency codes round trip', () {
    for (final c in Currency.values) {
      expect(Currency.fromCode(c.code), c);
    }
  });

  test('dates use Spanish', () {
    expect(formatDate(DateTime(2026, 10, 15)), '15 oct 2026');
    expect(formatShortDate(DateTime(2026, 1, 5)), '05/01/2026');
  });
}
