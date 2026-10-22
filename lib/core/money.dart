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
