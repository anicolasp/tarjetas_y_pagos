import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/notification_plan.dart';
import '../../core/router.dart';
import '../../services/providers.dart';
import '../auth/auth_controller.dart';
import '../cards/cards_providers.dart';

/// The screen of a tapped notification, waiting for the user to be inside
/// the app (after unlock, login or the setup wizard).
final notificationRouteProvider = NotifierProvider<NotificationRoute, String?>(
  NotificationRoute.new,
);

class NotificationRoute extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String route) => state = route;

  void clear() => state = null;
}

/// Keeps the scheduled reminders equal to the current data: every time the
/// finance snapshot loads (app start, any card/debt change, a new notice
/// days value) they are all replaced; on logout they are all cancelled.
/// Watched once from the app root.
final remindersProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final routes = ref.read(notificationRouteProvider.notifier);

  // One change at a time, in order: cancel + schedule never interleave.
  var queue = service
      .init(onTap: routes.open)
      .then((launch) => launch == null ? null : routes.open(launch))
      .catchError(_log);
  void enqueue(Future<void> Function() job) =>
      queue = queue.then((_) => job()).catchError(_log);

  // What is scheduled now, to skip the platform calls when a reload (a new
  // expense, a theme change…) leaves the plan as it was.
  String? scheduled;

  ref.listen(financeProvider, (_, next) {
    if (next case AsyncData(:final value)) {
      enqueue(() async {
        // No user while loading or locked (unlock pending): keep what is
        // scheduled. Only a logout cancels (below).
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final plan = planNotifications(
          value,
          now: ref.read(clockProvider)(),
          daysBefore: user.notifyDaysBefore,
        );
        final key = plan
            .map((n) => '${n.id}|${n.at}|${n.body}|${n.route}')
            .join('\n');
        if (key == scheduled) return;
        await service.replaceAll(plan);
        scheduled = key;
      });
    }
  }, fireImmediately: true);

  ref.listen(authControllerProvider, (_, next) {
    if (next is AuthLoggedOut) {
      enqueue(() async {
        await service.cancelAll();
        scheduled = null;
      });
    }
  });

  // Opens a tapped notification's screen once the user is inside the app.
  void openPending() {
    final route = ref.read(notificationRouteProvider);
    final auth = ref.read(authControllerProvider);
    if (route == null || auth is! AuthLoggedIn) return;
    if (ref.read(setupPendingProvider) == auth.user.id) return;
    routes.clear();
    ref.read(routerProvider).go(route);
  }

  ref.listen(notificationRouteProvider, (_, _) => openPending());
  ref.listen(authControllerProvider, (_, _) => openPending());
  ref.listen(setupPendingProvider, (_, _) => openPending());
});

void _log(Object error) {
  // A reminder that could not be scheduled must not break the app.
  debugPrint('Reminders: $error');
}
