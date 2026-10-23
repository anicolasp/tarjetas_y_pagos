/// Card statement math: balances, what to pay this cut and monthly spend.
/// Pure functions; amounts in cents and never mixed across currencies.
library;

import '../data/models/card_payment.dart';
import '../data/models/credit_card.dart';
import '../data/models/expense.dart';
import 'billing_cycle.dart';
import 'money.dart';

/// Per-currency figures of one card on a given day.
class CurrencyStatement {
  const CurrencyStatement({
    required this.currency,
    required this.balanceCents,
    required this.dueCents,
    required this.overdue,
  });

  final Currency currency;

  /// Everything spent minus everything paid. Negative = saldo a favor.
  final int balanceCents;

  /// "A pagar este corte": balance at the last cut minus payments made after
  /// it, never below 0.
  final int dueCents;

  /// The due date of the last cut passed and [dueCents] is still owed.
  final bool overdue;
}

class CardStatement {
  const CardStatement({
    required this.lastCut,
    required this.dueDate,
    required this.byCurrency,
  });

  /// The statement being paid closed on this date…
  final DateTime lastCut;

  /// …and must be paid by this one.
  final DateTime dueDate;

  /// One entry per currency the card holds (and any other with movements).
  final Map<Currency, CurrencyStatement> byCurrency;

  int balanceIn(Currency c) => byCurrency[c]?.balanceCents ?? 0;

  /// Balance per currency, for the ranking's available credit.
  Map<Currency, int> get balances => {
    for (final e in byCurrency.entries) e.key: e.value.balanceCents,
  };
}

CardStatement statementFor(
  CreditCard card,
  Iterable<Expense> expenses,
  Iterable<CardPayment> payments,
  DateTime today,
) {
  final cut = lastCut(today, card.cutDay);
  final due = dueDate(cut, card.paymentDays);
  final currencies = {
    ...card.currencies,
    for (final e in expenses) e.currency,
    for (final p in payments) p.currency,
  };

  bool onOrBeforeCut(DateTime d) => !dateOnly(d).isAfter(cut);

  return CardStatement(
    lastCut: cut,
    dueDate: due,
    byCurrency: {
      for (final c in currencies)
        c: () {
          final spent = [
            for (final e in expenses)
              if (e.currency == c) e,
          ];
          final paid = [
            for (final p in payments)
              if (p.currency == c) p,
          ];
          int sumE(Iterable<Expense> xs) =>
              xs.fold(0, (s, e) => s + e.amountCents);
          int sumP(Iterable<CardPayment> xs) =>
              xs.fold(0, (s, p) => s + p.amountCents);

          final atCut =
              sumE(spent.where((e) => onOrBeforeCut(e.date))) -
              sumP(paid.where((p) => onOrBeforeCut(p.date)));
          final paidAfter = sumP(paid.where((p) => !onOrBeforeCut(p.date)));
          final dueNow = atCut - paidAfter;
          final owed = dueNow > 0 ? dueNow : 0;
          return CurrencyStatement(
            currency: c,
            balanceCents: sumE(spent) - sumP(paid),
            dueCents: owed,
            overdue: owed > 0 && dateOnly(today).isAfter(due),
          );
        }(),
    },
  );
}

/// Spent in [today]'s calendar month, per currency.
Map<Currency, int> spentInMonth(Iterable<Expense> expenses, DateTime today) {
  final totals = <Currency, int>{};
  for (final e in expenses) {
    if (e.date.year == today.year && e.date.month == today.month) {
      totals[e.currency] = (totals[e.currency] ?? 0) + e.amountCents;
    }
  }
  return totals;
}
