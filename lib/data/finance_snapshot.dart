import '../core/billing_cycle.dart';
import '../core/money.dart';
import '../core/statement.dart';
import 'models/card_payment.dart';
import 'models/credit_card.dart';
import 'models/expense.dart';

/// Everything the money screens need, loaded once: the user's active cards
/// (in the order they were added) and all their expenses and payments.
/// Rankings, statements and totals are derived from it with pure functions,
/// so there is a single source of truth and no chain of derived providers.
class FinanceSnapshot {
  FinanceSnapshot({
    required this.cards,
    required this.expenses,
    required this.payments,
  });

  static final empty = FinanceSnapshot(
    cards: const [],
    expenses: const [],
    payments: const [],
  );

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
