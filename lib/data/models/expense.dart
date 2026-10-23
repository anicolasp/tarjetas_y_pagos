import '../../core/money.dart';
import 'db_codec.dart';

enum ExpenseSource {
  manual('manual'),
  ai('ia');

  const ExpenseSource(this.dbValue);

  final String dbValue;

  static ExpenseSource fromDb(String v) =>
      values.firstWhere((s) => s.dbValue == v);
}

class Expense {
  const Expense({
    this.id,
    required this.userId,
    required this.cardId,
    required this.categoryId,
    required this.merchant,
    required this.amountCents,
    required this.currency,
    required this.date,
    this.notes,
    this.source = ExpenseSource.manual,
    this.originalAmountCents,
    this.originalCurrency,
    this.exchangeRateMicros,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int cardId;
  final int categoryId;
  final String merchant;
  final int amountCents;
  final Currency currency;

  /// Calendar date of the purchase (time is ignored).
  final DateTime date;
  final String? notes;
  final ExpenseSource source;

  /// Set only when the expense was converted to the card currency: the
  /// amount and currency as paid, and the rate used (x 1,000,000).
  final int? originalAmountCents;
  final Currency? originalCurrency;
  final int? exchangeRateMicros;
  final DateTime createdAt;

  bool get wasConverted => originalCurrency != null;

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    cardId: m['card_id'] as int,
    categoryId: m['category_id'] as int,
    merchant: m['merchant'] as String,
    amountCents: m['amount_cents'] as int,
    currency: Currency.fromCode(m['currency'] as String),
    date: decodeDate(m['date'] as String),
    notes: m['notes'] as String?,
    source: ExpenseSource.fromDb(m['source'] as String),
    originalAmountCents: m['original_amount_cents'] as int?,
    originalCurrency: m['original_currency'] == null
        ? null
        : Currency.fromCode(m['original_currency'] as String),
    exchangeRateMicros: m['exchange_rate_micros'] as int?,
    createdAt: decodeTimestamp(m['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'card_id': cardId,
    'category_id': categoryId,
    'merchant': merchant,
    'amount_cents': amountCents,
    'currency': currency.code,
    'date': encodeDate(date),
    'notes': notes,
    'source': source.dbValue,
    'original_amount_cents': originalAmountCents,
    'original_currency': originalCurrency?.code,
    'exchange_rate_micros': exchangeRateMicros,
    'created_at': encodeTimestamp(createdAt),
  };

  Expense copyWith({
    int? id,
    int? cardId,
    int? categoryId,
    String? merchant,
    int? amountCents,
    Currency? currency,
    DateTime? date,
    String? notes,
    ExpenseSource? source,
    int? originalAmountCents,
    Currency? originalCurrency,
    int? exchangeRateMicros,
    bool clearNotes = false,
    bool clearConversion = false,
  }) => Expense(
    id: id ?? this.id,
    userId: userId,
    cardId: cardId ?? this.cardId,
    categoryId: categoryId ?? this.categoryId,
    merchant: merchant ?? this.merchant,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    notes: clearNotes ? null : notes ?? this.notes,
    source: source ?? this.source,
    originalAmountCents: clearConversion
        ? null
        : originalAmountCents ?? this.originalAmountCents,
    originalCurrency: clearConversion
        ? null
        : originalCurrency ?? this.originalCurrency,
    exchangeRateMicros: clearConversion
        ? null
        : exchangeRateMicros ?? this.exchangeRateMicros,
    createdAt: createdAt,
  );
}
