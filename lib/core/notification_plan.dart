import '../data/finance_snapshot.dart';
import 'billing_cycle.dart';
import 'router.dart';
import 'statement.dart';

/// Reminders go out at this local hour.
const notificationHour = 9;

enum ReminderKind { cut, payment, debt }

/// The wording of the reminders, in the user's language (the UI layer
/// builds it from the ARB texts).
abstract interface class ReminderTexts {
  String get title;

  /// The card cuts in [daysBefore] days (0 = today).
  String cut(String alias, int daysBefore);

  String payment(String alias, DateTime date);

  String debt(String creditor, DateTime date);
}

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
/// debt's due date. Times already past are left out, except the cut,
/// which moves to the following one.
///
/// Only the next occurrence is planned: the app replans on every start
/// and change, so a user who opens it at least once a cycle always has
/// the next reminders. A late statement gets no deadline reminder (its
/// date already passed, for every currency of the card).
List<PlannedNotification> planNotifications(
  FinanceSnapshot snapshot, {
  required DateTime now,
  required int daysBefore,
  required ReminderTexts texts,
}) {
  final today = dateOnly(now);
  final plan = <PlannedNotification>[];

  DateTime reminderAt(DateTime event) => DateTime(
    event.year,
    event.month,
    event.day - daysBefore,
    notificationHour,
  );

  void add(
    int entityId,
    ReminderKind kind,
    DateTime event,
    String body,
    String route,
  ) {
    final at = reminderAt(event);
    if (at.isBefore(now)) return;
    plan.add(
      PlannedNotification(
        id: notificationId(entityId, kind),
        at: at,
        title: texts.title,
        body: body,
        route: route,
      ),
    );
  }

  for (final card in snapshot.cards) {
    final id = card.id!;
    // Too close to this cut for the notice (it cuts tomorrow, notice is 3
    // days): remind of the following one instead of nothing.
    var cut = nextCut(today, card.cutDay);
    if (reminderAt(cut).isBefore(now)) {
      cut = cutInMonth(cut.year, cut.month + 1, card.cutDay);
    }
    add(
      id,
      ReminderKind.cut,
      cut,
      texts.cut(card.alias, daysBefore),
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
        texts.payment(card.alias, pay.date),
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
      texts.debt(s.debt.creditor, due),
      Routes.debtDetail(s.debt.id!),
    );
  }
  return plan;
}
