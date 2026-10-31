import '../../core/billing_cycle.dart';
import '../../core/formatters.dart';
import '../../l10n/l10n.dart';

/// "Corta en 28 días · pagas el 15/dic · 52 días", in the active language.
String explainRecommendation(
  AppLocalizations l,
  CardRecommendation r,
  DateTime today,
) {
  final cutIn = r.nextCut.difference(dateOnly(today)).inDays;
  return l.recommendationLine(
    l.cutsIn(cutIn),
    formatDayMonth(r.dueDate),
    l.daysCountPlain(r.financingDays),
  );
}
