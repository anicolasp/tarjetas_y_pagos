import 'db_codec.dart';

/// A partial payment (abono) towards a [Debt]; uses the debt's currency.
class DebtPayment {
  const DebtPayment({
    this.id,
    required this.debtId,
    required this.amountCents,
    required this.date,
    this.note,
  });

  final int? id;
  final int debtId;
  final int amountCents;
  final DateTime date;
  final String? note;

  factory DebtPayment.fromMap(Map<String, Object?> m) => DebtPayment(
    id: m['id'] as int?,
    debtId: m['debt_id'] as int,
    amountCents: m['amount_cents'] as int,
    date: decodeDate(m['date'] as String),
    note: m['note'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'debt_id': debtId,
    'amount_cents': amountCents,
    'date': encodeDate(date),
    'note': note,
  };
}
