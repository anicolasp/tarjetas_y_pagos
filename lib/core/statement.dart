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
    required this.overdueCents,
    required this.overdueSince,
  });

  final Currency currency;

  /// Everything spent minus everything paid. Negative = saldo a favor.
  final int balanceCents;

  /// "A pagar este corte": balance at the last cut minus payments made after
  /// it, never below 0.
  final int dueCents;

  /// Still owed from the most recent statement whose due date already
  /// passed (it may be older than the last cut). 0 when nothing is late.
  final int overdueCents;

  /// Due date of that late statement, or null when nothing is late.
  final DateTime? overdueSince;

  bool get overdue => overdueCents > 0;
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
  final day = dateOnly(today);
  final cut = lastCut(today, card.cutDay);
  final due = dueDate(cut, card.paymentDays);

  // The latest statement whose due date already passed: the last cut, or
  // an earlier one when its due date is still ahead (long payment terms).
  var lateCut = cut;
  while (!day.isAfter(dueDate(lateCut, card.paymentDays))) {
    lateCut = cutInMonth(lateCut.year, lateCut.month - 1, card.cutDay);
  }
  final lateDue = dueDate(lateCut, card.paymentDays);

  final currencies = {
    ...card.currencies,
    for (final e in expenses) e.currency,
    for (final p in payments) p.currency,
  };

  CurrencyStatement forCurrency(Currency c) {
    final spent = [
      for (final e in expenses)
        if (e.currency == c) e,
    ];
    final paid = [
      for (final p in payments)
        if (p.currency == c) p,
    ];

    /// Owed for the statement that closed on [closing]: its balance at that
    /// day minus everything paid afterwards, never below 0.
    int owedFor(DateTime closing) {
      bool onOrBefore(DateTime d) => !dateOnly(d).isAfter(closing);
      var owed = 0;
      for (final e in spent) {
        if (onOrBefore(e.date)) owed += e.amountCents;
      }
      for (final p in paid) {
        owed -= p.amountCents; // before: lowers the balance; after: pays it
      }
      return owed > 0 ? owed : 0;
    }

    final balance =
        spent.fold<int>(0, (s, e) => s + e.amountCents) -
        paid.fold<int>(0, (s, p) => s + p.amountCents);
    final late = owedFor(lateCut);
    return CurrencyStatement(
      currency: c,
      balanceCents: balance,
      dueCents: owedFor(cut),
      overdueCents: late,
      overdueSince: late > 0 ? lateDue : null,
    );
  }

  return CardStatement(
    lastCut: cut,
    dueDate: due,
    byCurrency: {for (final c in currencies) c: forCurrency(c)},
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
