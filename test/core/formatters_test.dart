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

  group('parseMoneyToCents', () {
    test('accepts plain, grouped and decimal amounts', () {
      expect(parseMoneyToCents('15000'), 1500000);
      expect(parseMoneyToCents('15,000.50'), 1500050);
      expect(parseMoneyToCents(' 0.5 '), 50);
      expect(parseMoneyToCents('0'), 0);
      expect(parseMoneyToCents('1,234,567.89'), 123456789);
      expect(parseMoneyToCents('9999999999999'), 999999999999900);
    });
    test('rejects invalid amounts', () {
      for (final bad in [
        '',
        'abc',
        '-5',
        '1.234',
        '1.2.3',
        '1e5',
        // Comma as decimal separator must not become 150050.
        '1500,50',
        // Malformed thousands groups.
        '1,2,3',
        '15,00',
        // Too many digits for int cents.
        '99999999999999999999',
      ]) {
        expect(parseMoneyToCents(bad), isNull, reason: bad);
      }
    });
    test('round trips with centsToInput', () {
      for (final cents in [0, 5, 50, 1500050, 123456789]) {
        expect(parseMoneyToCents(centsToInput(cents)), cents);
      }
      expect(centsToInput(1500050), '15000.50');
    });
  });

  test('day/month and month names in Spanish', () {
    expect(formatDayMonth(DateTime(2026, 12, 15)), '15/dic');
    expect(formatMonthName(DateTime(2026, 10, 1)), 'octubre');
  });
}
