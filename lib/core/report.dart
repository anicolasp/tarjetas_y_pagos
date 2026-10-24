/// Expense reports: totals and series aggregated in SQL (see
/// `ExpensesRepository.report`), read per currency. Currencies are never
/// added together.
library;

import 'money.dart';

/// Total, count and average of one currency.
class CurrencyTotals {
  const CurrencyTotals({
    required this.currency,
    required this.totalCents,
    required this.count,
  });

  final Currency currency;
  final int totalCents;
  final int count;

  /// Average per expense, rounded half up (amounts are positive).
  int get averageCents =>
      count == 0 ? 0 : (totalCents * 2 + count) ~/ (count * 2);
}

typedef CategoryTotal = ({
  int categoryId,
  Currency currency,
  int totalCents,
  int count,
});

typedef MonthTotal = ({DateTime month, Currency currency, int totalCents});

typedef CardTotal = ({int cardId, Currency currency, int totalCents});

/// The "Resto" slice: categories beyond the ones shown on their own.
typedef OtherCategories = ({int categories, int totalCents});

class ExpenseReport {
  const ExpenseReport({
    required this.totals,
    required this.byCategory,
    required this.byMonth,
    required this.byCard,
  });

  static const empty = ExpenseReport(
    totals: {},
    byCategory: [],
    byMonth: [],
    byCard: [],
  );

  final Map<Currency, CurrencyTotals> totals;
  final List<CategoryTotal> byCategory;
  final List<MonthTotal> byMonth;
  final List<CardTotal> byCard;

  bool get isEmpty => totals.isEmpty;

  /// Currencies with expenses, RD$ first.
  List<Currency> get currencies => [
    for (final c in Currency.values)
      if (totals.containsKey(c)) c,
  ];

  /// Largest first; ties by category id so the order is stable.
  List<CategoryTotal> categoriesIn(Currency c) =>
      [
        for (final t in byCategory)
          if (t.currency == c) t,
      ]..sort(
        (a, b) => b.totalCents != a.totalCents
            ? b.totalCents.compareTo(a.totalCents)
            : a.categoryId.compareTo(b.categoryId),
      );

  /// The [shown] largest categories of [c] and what is left, for a chart
  /// that must stay readable (a slice per category stops being legible).
  ({List<CategoryTotal> top, OtherCategories? rest}) topCategoriesIn(
    Currency c, {
    int shown = 5,
  }) {
    final all = categoriesIn(c);
    if (all.length <= shown + 1) return (top: all, rest: null);
    final rest = all.skip(shown);
    return (
      top: all.take(shown).toList(),
      rest: (
        categories: rest.length,
        totalCents: rest.fold(0, (s, t) => s + t.totalCents),
      ),
    );
  }

  /// One entry per calendar month from [from] to [to] (both included), with
  /// 0 for months without expenses. Without bounds, from the first to the
  /// last month with data.
  List<({DateTime month, int totalCents})> monthsIn(
    Currency c, {
    DateTime? from,
    DateTime? to,
  }) {
    final mine = {
      for (final m in byMonth)
        if (m.currency == c) m.month: m.totalCents,
    };
    if (mine.isEmpty && (from == null || to == null)) return const [];
    final sorted = mine.keys.toList()..sort();
    var month = from == null ? sorted.first : DateTime(from.year, from.month);
    final last = to == null ? sorted.last : DateTime(to.year, to.month);
    return [
      for (
        ;
        !month.isAfter(last);
        month = DateTime(month.year, month.month + 1)
      )
        (month: month, totalCents: mine[month] ?? 0),
    ];
  }

  /// Largest first; ties by card id.
  List<CardTotal> cardsIn(Currency c) =>
      [
        for (final t in byCard)
          if (t.currency == c) t,
      ]..sort(
        (a, b) => b.totalCents != a.totalCents
            ? b.totalCents.compareTo(a.totalCents)
            : a.cardId.compareTo(b.cardId),
      );
}

/// The quick periods of the reports filter.
enum ReportPeriod {
  thisMonth('Este mes'),
  lastMonth('Mes pasado'),
  last3Months('Últimos 3 meses'),
  custom('Rango');

  const ReportPeriod(this.label);

  final String label;

  /// Inclusive range for [today]; null for [custom] (the user picks it).
  ({DateTime from, DateTime to})? rangeFor(DateTime today) => switch (this) {
    thisMonth => (
      from: DateTime(today.year, today.month),
      to: DateTime(today.year, today.month + 1, 0),
    ),
    lastMonth => (
      from: DateTime(today.year, today.month - 1),
      to: DateTime(today.year, today.month, 0),
    ),
    last3Months => (
      from: DateTime(today.year, today.month - 2),
      to: DateTime(today.year, today.month + 1, 0),
    ),
    custom => null,
  };
}
