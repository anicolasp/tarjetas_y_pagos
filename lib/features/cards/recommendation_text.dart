import '../../core/billing_cycle.dart';
import '../../core/formatters.dart';
import '../../l10n/l10n.dart';

/// "Corta en 28 días · pagas el 15/dic · 52 días", in the active language.
/// [spoken] writes the date in full ("15 dic 2026") for screen readers,
/// which would read "15/dic" as "15 slash dic" (#40).
String explainRecommendation(
  AppLocalizations l,
  CardRecommendation r,
  DateTime today, {
  bool spoken = false,
}) {
  final cutIn = r.nextCut.difference(dateOnly(today)).inDays;
  return l.recommendationLine(
    l.cutsIn(cutIn),
    spoken ? formatDate(r.dueDate) : formatDayMonth(r.dueDate),
    l.daysCountPlain(r.financingDays),
  );
}
