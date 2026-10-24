import '../core/billing_cycle.dart';
import '../core/debts.dart';
import '../core/money.dart';
import '../core/statement.dart';
import 'models/card_payment.dart';
import 'models/credit_card.dart';
import 'models/debt.dart';
import 'models/debt_payment.dart';
import 'models/expense.dart';

/// Everything the money screens need, loaded once: the user's active cards
/// (in the order they were added), all their expenses and card payments,
/// and their other debts with their payments.
/// Rankings, statements and totals are derived from it with pure functions,
/// so there is a single source of truth and no chain of derived providers.
class FinanceSnapshot {
  FinanceSnapshot({
    required this.cards,
    required this.expenses,
    required this.payments,
    this.debts = const [],
    this.debtPayments = const [],
  });

  static final empty = FinanceSnapshot(
    cards: const [],
    expenses: const [],
    payments: const [],
  );

  /// Debts outside the cards, active and settled.
  final List<Debt> debts;

  /// All payments (abonos) of [debts], newest first.
  final List<DebtPayment> debtPayments;

  late final List<DebtSummary> debtSummaries = [
    for (final d in debts) summarize(d, debtPayments),
  ];

  DebtSummary? debtSummary(int id) {
    for (final s in debtSummaries) {
      if (s.debt.id == id) return s;
    }
    return null;
  }

  /// What is left of the active debts, per currency.
  Map<Currency, int> otherDebt() {
    final totals = <Currency, int>{};
    for (final s in debtSummaries) {
      if (!s.settled) {
        totals[s.debt.currency] =
            (totals[s.debt.currency] ?? 0) + s.remainingCents;
      }
    }
    return totals;
  }

  /// Cards plus other debts, per currency (never mixed).
  Map<Currency, int> totalDebt(DateTime today) {
    final totals = {...debt(today)};
    for (final MapEntry(key: c, value: cents) in otherDebt().entries) {
      totals[c] = (totals[c] ?? 0) + cents;
    }
    return totals;
  }

  /// Active cards, oldest first.
  final List<CreditCard> cards;

  /// All of the user's expenses (archived cards included), newest first.
  final List<Expense> expenses;

  /// All of the user's card payments, newest first.
  final List<CardPayment> payments;

  CreditCard? card(int id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Expense> expensesOf(int cardId) => [
    for (final e in expenses)
      if (e.cardId == cardId) e,
  ];

  List<CardPayment> paymentsOf(int cardId) => [
    for (final p in payments)
      if (p.cardId == cardId) p,
  ];

  /// Statements are computed once per card and day: a screen asks for the
  /// same ones several times per build (ranking, list, debt).
  final _statements = <(int, DateTime), CardStatement>{};

  CardStatement statementOf(CreditCard card, DateTime today) =>
      _statements.putIfAbsent(
        (card.id!, dateOnly(today)),
        () => statementFor(
          card,
          expensesOf(card.id!),
          paymentsOf(card.id!),
          today,
        ),
      );

  /// "Mejor tarjeta hoy", with real balances.
  List<CardRecommendation> ranking(DateTime today) => rankCards(
    cards,
    today,
    balances: {for (final c in cards) c.id!: statementOf(c, today).balances},
  );

  /// The ranking data in the order the cards were added (lists, carousel).
  List<CardRecommendation> inAddedOrder(DateTime today) {
    final byId = {for (final r in ranking(today)) r.card.id: r};
    return [for (final c in cards) ?byId[c.id]];
  }

  Map<Currency, int> spentThisMonth(DateTime today) =>
      spentInMonth(expenses, today);

  /// What the active cards owe, per currency (credit balances ignored).
  Map<Currency, int> debt(DateTime today) {
    final totals = <Currency, int>{};
    for (final c in cards) {
      for (final s in statementOf(c, today).byCurrency.values) {
        if (s.balanceCents > 0) {
          totals[s.currency] = (totals[s.currency] ?? 0) + s.balanceCents;
        }
      }
    }
    return totals;
  }
}
