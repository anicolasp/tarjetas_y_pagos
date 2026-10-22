import '../../core/money.dart';
import 'db_codec.dart';

enum DebtStatus {
  active('activa'),
  settled('saldada');

  const DebtStatus(this.dbValue);

  final String dbValue;

  static DebtStatus fromDb(String v) =>
      values.firstWhere((s) => s.dbValue == v);
}

/// A debt outside the credit cards (loans, money owed to people or banks).
class Debt {
  const Debt({
    this.id,
    required this.userId,
    required this.creditor,
    this.description,
    required this.amountCents,
    required this.currency,
    this.dueDate,
    this.status = DebtStatus.active,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String creditor;
  final String? description;
  final int amountCents;
  final Currency currency;
  final DateTime? dueDate;
  final DebtStatus status;
  final DateTime createdAt;

  factory Debt.fromMap(Map<String, Object?> m) => Debt(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    creditor: m['creditor'] as String,
    description: m['description'] as String?,
    amountCents: m['amount_cents'] as int,
    currency: Currency.fromCode(m['currency'] as String),
    dueDate: m['due_date'] == null ? null : decodeDate(m['due_date'] as String),
    status: DebtStatus.fromDb(m['status'] as String),
    createdAt: decodeTimestamp(m['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'creditor': creditor,
    'description': description,
    'amount_cents': amountCents,
    'currency': currency.code,
    'due_date': dueDate == null ? null : encodeDate(dueDate!),
    'status': status.dbValue,
    'created_at': encodeTimestamp(createdAt),
  };

  Debt copyWith({
    int? id,
    String? creditor,
    String? description,
    int? amountCents,
    Currency? currency,
    DateTime? dueDate,
    DebtStatus? status,
    bool clearDescription = false,
    bool clearDueDate = false,
  }) => Debt(
    id: id ?? this.id,
    userId: userId,
    creditor: creditor ?? this.creditor,
    description: clearDescription ? null : description ?? this.description,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
