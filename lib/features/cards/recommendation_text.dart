import '../../core/billing_cycle.dart';
import '../../core/formatters.dart';

/// "Corta en 28 días · pagas el 15/dic · 52 días"
String explainRecommendation(CardRecommendation r, DateTime today) {
  final cutIn = r.nextCut.difference(dateOnly(today)).inDays;
  final cut = switch (cutIn) {
    0 => 'Corta hoy',
    1 => 'Corta mañana',
    _ => 'Corta en $cutIn días',
  };
  return '$cut · pagas el ${formatDayMonth(r.dueDate)} · '
      '${r.financingDays} días';
}
