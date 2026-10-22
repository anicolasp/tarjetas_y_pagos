import 'package:intl/intl.dart';

import 'money.dart';

/// App locale for dates. Call `initializeDateFormatting(appLocale)` once
/// before using the date formatters.
const appLocale = 'es';

final _amount = NumberFormat('#,##0.00', 'en_US');

/// `formatMoney(125000, Currency.dop)` → `RD$ 1,250.00`.
String formatMoney(int cents, Currency currency) {
  final sign = cents < 0 ? '-' : '';
  return '$sign${currency.symbol} ${_amount.format(cents.abs() / 100)}';
}

/// Plain digits ("15000.5") or well-formed thousands groups ("15,000.50").
/// A comma used as the decimal separator ("1500,50") is rejected instead of
/// being read as 150050. Up to 13 integer digits so the cents fit an int.
final _moneyInput = RegExp(r'^(\d{1,13}|\d{1,3}(,\d{3}){1,4})(\.\d{1,2})?$');

/// Parses a typed amount ("15000", "15,000.50", " 0.5 ") into cents, or null
/// if it is not a valid non-negative amount. Uses integer math, no doubles.
int? parseMoneyToCents(String input) {
  final s = input.trim();
  if (!_moneyInput.hasMatch(s)) return null;
  final parts = s.replaceAll(',', '').split('.');
  final cents = parts.length == 2 ? parts[1].padRight(2, '0') : '00';
  return int.parse(parts[0]) * 100 + int.parse(cents);
}

/// Cents as an editable amount without grouping: 1500050 → "15000.50".
String centsToInput(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

/// `15 oct 2026`
String formatDate(DateTime d) => DateFormat('d MMM y', appLocale).format(d);

/// `15/10/2026`
String formatShortDate(DateTime d) =>
    DateFormat('dd/MM/y', appLocale).format(d);

/// `15/dic`
String formatDayMonth(DateTime d) =>
    '${d.day}/${DateFormat('MMM', appLocale).format(d).replaceAll('.', '')}';

/// `octubre`
String formatMonthName(DateTime d) => DateFormat('MMMM', appLocale).format(d);
