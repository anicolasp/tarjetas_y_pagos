import '../../core/money.dart';
import 'db_codec.dart';

enum CardBrand {
  visa('visa', 'Visa'),
  mastercard('mastercard', 'Mastercard'),
  amex('amex', 'American Express'),
  other('otra', 'Otra');

  const CardBrand(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static CardBrand fromDb(String v) => values.firstWhere((b) => b.dbValue == v);
}

/// A credit card. Only the last 4 digits are ever stored.
class CreditCard {
  const CreditCard({
    this.id,
    required this.userId,
    required this.alias,
    required this.bank,
    required this.brand,
    required this.last4,
    required this.cutDay,
    this.paymentDays = 20,
    this.creditLimitCents = 0,
    required this.currency,
    required this.color,
    this.archived = false,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String alias;
  final String bank;
  final CardBrand brand;
  final String last4;

  /// Day of month the statement closes (1–31, clamped to month end).
  final int cutDay;

  /// Days between the cut date and the payment due date.
  final int paymentDays;
  final int creditLimitCents;
  final Currency currency;
  final int color;
  final bool archived;
  final DateTime createdAt;

  factory CreditCard.fromMap(Map<String, Object?> m) => CreditCard(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    alias: m['alias'] as String,
    bank: m['bank'] as String,
    brand: CardBrand.fromDb(m['brand'] as String),
    last4: m['last4'] as String,
    cutDay: m['cut_day'] as int,
    paymentDays: m['payment_days'] as int,
    creditLimitCents: m['credit_limit_cents'] as int,
    currency: Currency.fromCode(m['currency'] as String),
    color: m['color'] as int,
    archived: decodeBool(m['archived']),
    createdAt: decodeTimestamp(m['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'alias': alias,
    'bank': bank,
    'brand': brand.dbValue,
    'last4': last4,
    'cut_day': cutDay,
    'payment_days': paymentDays,
    'credit_limit_cents': creditLimitCents,
    'currency': currency.code,
    'color': color,
    'archived': encodeBool(archived),
    'created_at': encodeTimestamp(createdAt),
  };

  CreditCard copyWith({
    int? id,
    String? alias,
    String? bank,
    CardBrand? brand,
    String? last4,
    int? cutDay,
    int? paymentDays,
    int? creditLimitCents,
    Currency? currency,
    int? color,
    bool? archived,
  }) => CreditCard(
    id: id ?? this.id,
    userId: userId,
    alias: alias ?? this.alias,
    bank: bank ?? this.bank,
    brand: brand ?? this.brand,
    last4: last4 ?? this.last4,
    cutDay: cutDay ?? this.cutDay,
    paymentDays: paymentDays ?? this.paymentDays,
    creditLimitCents: creditLimitCents ?? this.creditLimitCents,
    currency: currency ?? this.currency,
    color: color ?? this.color,
    archived: archived ?? this.archived,
    createdAt: createdAt,
  );
}
