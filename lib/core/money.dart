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
    _div(BigInt.from(cents) * BigInt.from(rateMicros), BigInt.from(rateScale));

/// Half-up integer division in BigInt: no 64-bit overflow on huge amounts.
int _div(BigInt n, BigInt d) => ((n + d ~/ BigInt.two) ~/ d).toInt();

/// Converts [cents] from [from] to [to] with the RD$-per-US$ rate. US$→RD$
/// multiplies; RD$→US$ divides (exact, instead of an imprecise inverse
/// rate). Rounds half up to the cent.
int convertBetween(int cents, Currency from, Currency to, int usdToDopMicros) {
  if (from == to) return cents;
  if (from == Currency.usd) return convertCents(cents, usdToDopMicros);
  return _div(
    BigInt.from(cents) * BigInt.from(rateScale),
    BigInt.from(usdToDopMicros),
  );
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
