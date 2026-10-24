/// Debt math: paid, remaining, progress and overdue. Pure functions; a
/// debt and its payments always share one currency.
library;

import '../data/models/debt.dart';
import '../data/models/debt_payment.dart';
import 'billing_cycle.dart';

class DebtSummary {
  const DebtSummary({required this.debt, required this.paidCents});

  final Debt debt;
  final int paidCents;

  int get remainingCents => debt.amountCents - paidCents;

  /// Share already paid, 0 to 1.
  double get progress => (paidCents / debt.amountCents).clamp(0, 1).toDouble();

  bool get settled => remainingCents <= 0;

  /// Past its due date with something still owed.
  bool overdue(DateTime today) =>
      !settled &&
      debt.dueDate != null &&
      dateOnly(debt.dueDate!).isBefore(dateOnly(today));
}

DebtSummary summarize(Debt debt, Iterable<DebtPayment> payments) => DebtSummary(
  debt: debt,
  paidCents: payments
      .where((p) => p.debtId == debt.id)
      .fold(0, (sum, p) => sum + p.amountCents),
);
