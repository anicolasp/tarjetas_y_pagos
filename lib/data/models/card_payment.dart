import '../../core/money.dart';
import 'db_codec.dart';

/// A payment made towards a card balance.
class CardPayment {
  const CardPayment({
    this.id,
    required this.cardId,
    required this.amountCents,
    required this.currency,
    required this.date,
    this.note,
  });

  final int? id;
  final int cardId;
  final int amountCents;
  final Currency currency;
  final DateTime date;
  final String? note;

  factory CardPayment.fromMap(Map<String, Object?> m) => CardPayment(
    id: m['id'] as int?,
    cardId: m['card_id'] as int,
    amountCents: m['amount_cents'] as int,
    currency: Currency.fromCode(m['currency'] as String),
    date: decodeDate(m['date'] as String),
    note: m['note'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'card_id': cardId,
    'amount_cents': amountCents,
    'currency': currency.code,
    'date': encodeDate(date),
    'note': note,
  };
}
