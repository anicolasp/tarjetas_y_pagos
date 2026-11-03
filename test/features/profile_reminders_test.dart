import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// "Activar recordatorios" in Mi perfil (#31): the status of the
/// notification permission and a way to allow it. Fictitious data.
void main() {
  late AppDatabase db;
  late FakeNotificationService notifications;

  setUpAll(initializeDateFormatting);

  setUp(() async {
    db = await openTestDatabase();
    await seedUser(db);
    notifications = FakeNotificationService();
  });

  tearDown(() async {
    Intl.defaultLocale = appLocale;
    await db.close();
  });

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: InMemorySecureStore()..values['session_user_id'] = '1',
          notifications: notifications,
          now: DateTime(2026, 10, 25, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push('/home/profile');
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  /// Leaves the app (to the phone settings) and comes back.
  Future<void> leaveAndReturn(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('with the permission: "Recordatorios activados"', (tester) async {
    notifications.granted = true;
    await start(tester);
    expect(key('profile.reminders.on'), findsOneWidget);
    expect(find.text('Recordatorios activados'), findsOneWidget);
    expect(key('profile.reminders.enable'), findsNothing);
  });

  testWidgets('E2E 2–3: without it, the button asks and then shows it on', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Recordatorios desactivados'), findsOneWidget);
    expect(find.text('Activa los permisos para recibirlos.'), findsOneWidget);

    await tap(tester, 'profile.reminders.enable');
    expect(notifications.permissionRequests, 1);
    expect(key('profile.reminders.on'), findsOneWidget);
    expect(notifications.settingsOpened, 0);
  });

  testWidgets('E2E 4: denied, it offers the settings; back from them, the '
      'status is updated', (tester) async {
    notifications.permission = false;
    await start(tester);
    await tap(tester, 'profile.reminders.enable');
    expect(
      find.text('Puedes activarlos en los ajustes del teléfono.'),
      findsOneWidget,
    );
    expect(key('profile.reminders.off'), findsOneWidget);

    await tester.tap(key('profile.reminders.openSettings'));
    await tester.pumpAndSettle();
    expect(notifications.settingsOpened, 1);

    // Allowed in the phone settings, then back to the app.
    notifications.granted = true;
    await leaveAndReturn(tester);
    expect(key('profile.reminders.on'), findsOneWidget);
  });

  testWidgets('a request that fails still offers the settings', (tester) async {
    notifications.requestError = Exception('no activity');
    await start(tester);
    await tap(tester, 'profile.reminders.enable');
    expect(key('profile.reminders.openSettings'), findsOneWidget);
    // The button is usable again.
    final button = tester.widget<ButtonStyleButton>(
      key('profile.reminders.enable'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('without a settings screen it explains where to go', (
    tester,
  ) async {
    notifications
      ..permission = false
      ..settingsError = Exception('no settings channel');
    await start(tester);
    await tap(tester, 'profile.reminders.enable');
    await tester.tap(key('profile.reminders.openSettings'));
    await tester.pumpAndSettle();
    expect(
      find.text('Abre los ajustes del teléfono para permitirlo'),
      findsOneWidget,
    );
  });

  testWidgets('allowing it does not touch the scheduled reminders', (
    tester,
  ) async {
    await start(tester);
    final replaces = notifications.replaces;
    final cancels = notifications.cancels;
    await tap(tester, 'profile.reminders.enable');
    expect(notifications.replaces, replaces);
    expect(notifications.cancels, cancels);
  });

  testWidgets('in English', (tester) async {
    await db.db.update('users', {'language': 'en'});
    await start(tester);
    expect(find.text('Reminders off'), findsOneWidget);
    expect(find.text('Turn on reminders'), findsOneWidget);
  });

  // Rule #2: the off block (the larger one) in every size, both themes and
  // the three languages.
  for (final language in ['es', 'en', 'fr']) {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('$language ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await db.db.update('users', {'language': language});
          await start(tester);
          await tester.ensureVisible(key('profile.reminders.enable'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(key('profile.reminders.off'), findsOneWidget);
        });
      }
    }
  }
}
