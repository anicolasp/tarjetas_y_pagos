/// Currencies supported by the app. Amounts are always stored as integer
/// cents together with their currency; totals never mix currencies.
enum Currency {
  dop('DOP', 'RD\$'),
  usd('USD', 'US\$');

  const Currency(this.code, this.symbol);

  /// ISO-4217 code, used as the database value.
  final String code;
  final String symbol;

  static Currency fromCode(String code) =>
      values.firstWhere((c) => c.code == code);
}

/// Exchange rates are stored as integers: rate x 1,000,000 ("micros"), so
/// 61.409228 RD$ per US$ is 61409228.
const rateScale = 1000000;

/// Converts [cents] with [rateMicros] (units of the target currency per unit
/// of the source currency), rounding half up to the cent. Integer math only.
int convertCents(int cents, int rateMicros) =>
    (cents * rateMicros + rateScale ~/ 2) ~/ rateScale;

/// Rate to convert [from] into [to] given the USD→DOP rate.
int rateMicrosFor(Currency from, Currency to, int usdToDopMicros) {
  if (from == to) return rateScale;
  return from == Currency.usd
      ? usdToDopMicros
      : (rateScale * rateScale + usdToDopMicros ~/ 2) ~/ usdToDopMicros;
}

/// "61.409228" → 61409228, or null if not a positive number with up to 6
/// decimals.
int? parseRateMicros(String input) {
  final s = input.trim().replaceAll(',', '.');
  final m = RegExp(r'^(\d{1,6})(?:\.(\d{1,6}))?$').firstMatch(s);
  if (m == null) return null;
  final micros =
      int.parse(m[1]!) * rateScale + int.parse((m[2] ?? '').padRight(6, '0'));
  return micros > 0 ? micros : null;
}

/// 61409228 → "61.409228" (trailing zeros trimmed, at least 2 decimals).
String formatRate(int micros) {
  var decimals = (micros % rateScale).toString().padLeft(6, '0');
  while (decimals.length > 2 && decimals.endsWith('0')) {
    decimals = decimals.substring(0, decimals.length - 1);
  }
  return '${micros ~/ rateScale}.$decimals';
}
