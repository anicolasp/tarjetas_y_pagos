import '../data/finance_snapshot.dart';
import 'billing_cycle.dart';
import 'formatters.dart';
import 'router.dart';
import 'statement.dart';

/// Reminders go out at this local hour.
const notificationHour = 9;

enum ReminderKind { cut, payment, debt }

/// A local notification to schedule.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  /// Stable per entity and kind, so rescheduling replaces it.
  final int id;

  /// Local date and time.
  final DateTime at;
  final String title;
  final String body;

  /// Where tapping it goes.
  final String route;

  @override
  String toString() => 'PlannedNotification($id, $at, $body)';
}

/// `entityId × 4 + kind`: card and debt ids may repeat, the kind keeps the
/// ids apart.
int notificationId(int entityId, ReminderKind kind) =>
    entityId * 4 + kind.index;

/// The reminders [daysBefore] days ahead of each card's next cut and
/// payment deadline (only when it owes something) and of each active
/// debt's due date. Times already past are left out.
List<PlannedNotification> planNotifications(
  FinanceSnapshot snapshot, {
  required DateTime now,
  required int daysBefore,
}) {
  final today = dateOnly(now);
  final plan = <PlannedNotification>[];

  void add(
    int entityId,
    ReminderKind kind,
    DateTime event,
    String body,
    String route,
  ) {
    final at = DateTime(
      event.year,
      event.month,
      event.day - daysBefore,
      notificationHour,
    );
    if (at.isBefore(now)) return;
    plan.add(
      PlannedNotification(
        id: notificationId(entityId, kind),
        at: at,
        title: 'Tarjetas y Pagos',
        body: body,
        route: route,
      ),
    );
  }

  final inDays = switch (daysBefore) {
    0 => 'hoy',
    1 => 'mañana',
    _ => 'en $daysBefore días',
  };

  for (final card in snapshot.cards) {
    final id = card.id!;
    add(
      id,
      ReminderKind.cut,
      nextCut(today, card.cutDay),
      'Tu tarjeta ${card.alias} corta $inDays',
      Routes.cardDetail(id),
    );
    final statement = snapshot.statementOf(card, today);
    final owes = statement.byCurrency.values.any((s) => s.balanceCents > 0);
    final pay = payBy(card, statement, today);
    if (owes && !pay.overdue) {
      add(
        id,
        ReminderKind.payment,
        pay.date,
        'Fecha límite de pago de ${card.alias}: ${formatDate(pay.date)}',
        Routes.cardDetail(id),
      );
    }
  }

  for (final s in snapshot.debtSummaries) {
    final due = s.debt.dueDate;
    if (s.settled || due == null) continue;
    add(
      s.debt.id!,
      ReminderKind.debt,
      due,
      'La deuda con ${s.debt.creditor} vence el ${formatDate(due)}',
      Routes.debtDetail(s.debt.id!),
    );
  }
  return plan;
}
