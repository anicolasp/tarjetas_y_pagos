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

/// `15 oct 2026`
String formatDate(DateTime d) => DateFormat('d MMM y', appLocale).format(d);

/// `15/10/2026`
String formatShortDate(DateTime d) =>
    DateFormat('dd/MM/y', appLocale).format(d);
