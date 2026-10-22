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
  final DateTime createdAt;

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
    bool clearNotes = false,
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
    createdAt: createdAt,
  );
}
