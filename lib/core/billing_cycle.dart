/// Credit card billing cycle math. Pure functions over calendar days: every
/// date is normalized with [dateOnly] (UTC midnight) so time of day and DST
/// never shift a result by one day.
library;

import '../data/models/credit_card.dart';

/// Below this share of the limit left, a card is "low credit".
const lowCreditRatio = 0.10;

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// The cut date of [month] (may be 0 or 13; DateTime normalizes it), with the
/// cut day clamped to the month length: day 31 in April is the 30th.
DateTime cutInMonth(int year, int month, int cutDay) {
  final first = DateTime.utc(year, month);
  return DateTime.utc(
    first.year,
    first.month,
    cutDay.clamp(1, daysInMonth(first.year, first.month)),
  );
}

/// The statement that is open today closes on this date. A purchase made on
/// the cut day itself still belongs to that day's statement.
DateTime nextCut(DateTime today, int cutDay) {
  final t = dateOnly(today);
  final thisMonth = cutInMonth(t.year, t.month, cutDay);
  return t.isAfter(thisMonth)
      ? cutInMonth(t.year, t.month + 1, cutDay)
      : thisMonth;
}

/// The cut before [nextCut]: the open statement covers (lastCut, nextCut].
DateTime lastCut(DateTime today, int cutDay) {
  final next = nextCut(today, cutDay);
  return cutInMonth(next.year, next.month - 1, cutDay);
}

DateTime dueDate(DateTime cut, int paymentDays) =>
    dateOnly(cut).add(Duration(days: paymentDays));

/// Days from [today] until a purchase made today must be paid.
int financingDays(DateTime today, int cutDay, int paymentDays) => dueDate(
  nextCut(today, cutDay),
  paymentDays,
).difference(dateOnly(today)).inDays;

class CardRecommendation {
  const CardRecommendation({
    required this.card,
    required this.nextCut,
    required this.dueDate,
    required this.financingDays,
    required this.availableCents,
  });

  final CreditCard card;
  final DateTime nextCut;
  final DateTime dueDate;
  final int financingDays;

  /// Null when the card has no limit registered (limit 0).
  final int? availableCents;

  bool get lowCredit =>
      availableCents != null &&
      availableCents! < card.creditLimitCents * lowCreditRatio;
}

/// Active cards from best to worst to use [today]: cards with enough credit
/// first, then low-credit ones; each group by most financing days, then most
/// available credit, then alias.
List<CardRecommendation> rankCards(
  Iterable<CreditCard> cards,
  DateTime today, {
  Map<int, int> balancesCents = const {},
}) {
  final ranked = [
    for (final card in cards)
      if (!card.archived)
        CardRecommendation(
          card: card,
          nextCut: nextCut(today, card.cutDay),
          dueDate: dueDate(nextCut(today, card.cutDay), card.paymentDays),
          financingDays: financingDays(today, card.cutDay, card.paymentDays),
          availableCents: card.creditLimitCents == 0
              ? null
              : card.creditLimitCents - (balancesCents[card.id] ?? 0),
        ),
  ];
  ranked.sort((a, b) {
    if (a.lowCredit != b.lowCredit) return a.lowCredit ? 1 : -1;
    final byDays = b.financingDays.compareTo(a.financingDays);
    if (byDays != 0) return byDays;
    final byAvailable = (b.availableCents ?? -1).compareTo(
      a.availableCents ?? -1,
    );
    if (byAvailable != 0) return byAvailable;
    return a.card.alias.toLowerCase().compareTo(b.card.alias.toLowerCase());
  });
  return ranked;
}
