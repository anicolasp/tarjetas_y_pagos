import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/core/notification_plan.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/repositories/debts_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/security.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Setup wizard after registering, and the local reminders. "Today" is
/// Sunday 25 Oct 2026, 10:00. Emails are fictitious.
void main() {
  late AppDatabase db;
  late InMemorySecureStore store;
  late FakeNotificationService notifications;

  final now = DateTime(2026, 10, 25, 10);

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    store = InMemorySecureStore();
    notifications = FakeNotificationService();
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    FakeBiometricService? biometrics,
  }) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true, ...prefs},
          secureStore: store,
          biometrics: biometrics,
          notifications: notifications,
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  Future<void> register(WidgetTester tester) async {
    await tap(tester, 'login.register');
    await tester.enterText(key('register.firstName'), 'Ana');
    await tester.enterText(key('register.lastName'), 'Prueba');
    await tester.enterText(key('register.email'), 'ana@example.com');
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await pickSecurityQuestion(tester, 'register');
    await tap(tester, 'register.submit');
  }

  /// A logged-in user who still has the wizard ahead.
  Future<AppUser> pendingUser() async {
    final user = await seedUser(db);
    store.values['session_user_id'] = '${user.id}';
    return user;
  }

  String stepLabel(WidgetTester tester) =>
      tester.widget<Text>(key('setup.stepLabel')).data!;

  testWidgets('E2E 1–3: register, wizard in 4 steps, US\$ expense and '
      'the cut reminder is scheduled', (tester) async {
    await start(tester);
    await register(tester);

    // 1. Currency.
    expect(key('setup.root'), findsOneWidget);
    expect(stepLabel(tester), 'Paso 1 de 4');
    await tap(tester, 'setup.currency.USD');
    await tap(tester, 'setup.next');

    // 2. First card, with the existing form.
    expect(stepLabel(tester), 'Paso 2 de 4');
    await tap(tester, 'setup.addCard');
    expect(key('cardForm.root'), findsOneWidget);
    await tester.enterText(key('cardForm.alias'), 'Viajes');
    await tester.enterText(key('cardForm.bank'), 'Banco Prueba');
    await tester.enterText(key('cardForm.last4'), '5555');
    await tester.enterText(key('cardForm.cutDay'), '28'); // in 3 days
    await tap(tester, 'cardForm.save');

    // 3. Biometrics: not now.
    expect(key('setup.root'), findsOneWidget);
    expect(stepLabel(tester), 'Paso 3 de 4');
    await tap(tester, 'setup.biometricLater');

    // 4. Notifications: 3 days by default, permission asked.
    expect(stepLabel(tester), 'Paso 4 de 4');
    expect(find.text('3 días'), findsOneWidget);
    await tap(tester, 'setup.notificationsOn');
    expect(notifications.permissionRequests, 1);
    expect(key('home.root'), findsOneWidget);

    // E2E 2: a new expense starts in US$ (the card took the default too).
    await tester.tap(find.text('Nuevo gasto'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(key('expenseForm.currency.USD')).selected,
      isTrue,
    );

    // E2E 3: the card cuts on the 28th; 3 days before is today at 9:00,
    // already past at 10:00, so it reminds of the next cut (28 Nov).
    final cut = notifications.scheduled.singleWhere(
      (n) => n.body.contains('corta'),
    );
    expect(cut.at, DateTime(2026, 11, 25, 9));
  });

  testWidgets('E2E 3: with N days the cut reminder is pending', (tester) async {
    final user = await seedUser(db);
    store.values['session_user_id'] = '${user.id}';
    // Cuts on the 31st (6 days); 3 days before → 28 Oct at 9:00.
    final card = await seedCard(db, user.id!, alias: 'Viajes', cutDay: 31);
    await start(tester);
    final cut = notifications.scheduled.singleWhere(
      (n) => n.id == notificationId(card.id!, ReminderKind.cut),
    );
    expect(cut.at, DateTime(2026, 10, 28, 9));
    expect(cut.body, 'Tu tarjeta Viajes corta en 3 días');
  });

  testWidgets('E2E 4: "Omitir" goes straight to Home, for good', (
    tester,
  ) async {
    await start(tester);
    await register(tester);
    await tap(tester, 'setup.skip');
    expect(key('home.root'), findsOneWidget);
    expect(notifications.permissionRequests, 0);

    await tester.pumpWidget(const SizedBox());
    await start(tester);
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('closed halfway, the wizard comes back', (tester) async {
    final user = await pendingUser();
    await start(tester, prefs: {'setup_pending_user': user.id!});
    expect(key('setup.root'), findsOneWidget);
    await tap(tester, 'setup.next');

    await tester.pumpWidget(const SizedBox());
    await start(tester, prefs: {'setup_pending_user': user.id!});
    expect(key('setup.root'), findsOneWidget);
  });

  testWidgets('a user who logs in (not registering) never sees it', (
    tester,
  ) async {
    await seedUser(db, email: 'ana@example.com');
    await start(tester);
    await tester.enterText(key('login.email'), 'ana@example.com');
    await tester.enterText(key('login.password'), 'abc12345');
    await tap(tester, 'login.submit');
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('back goes to the previous step; "Lo haré después" skips '
      'the card', (tester) async {
    final user = await pendingUser();
    await start(tester, prefs: {'setup_pending_user': user.id!});
    await tap(tester, 'setup.next');
    await tap(tester, 'setup.cardLater');
    expect(stepLabel(tester), 'Paso 3 de 4');
    await tap(tester, 'setup.back');
    expect(stepLabel(tester), 'Paso 2 de 4');
  });

  testWidgets('biometrics: on with a fingerprint, explained without one', (
    tester,
  ) async {
    final user = await pendingUser();
    await start(
      tester,
      prefs: {'setup_pending_user': user.id!},
      biometrics: FakeBiometricService(available: false),
    );
    await tap(tester, 'setup.next');
    await tap(tester, 'setup.cardLater');
    await tap(tester, 'setup.biometricOn');
    expect(
      find.text('Configura una huella en los ajustes del teléfono primero.'),
      findsOneWidget,
    );
    expect(stepLabel(tester), 'Paso 3 de 4');
  });

  testWidgets('notifications denied: explains it and still finishes', (
    tester,
  ) async {
    notifications.permission = false;
    final user = await pendingUser();
    await start(tester, prefs: {'setup_pending_user': user.id!});
    await tap(tester, 'setup.next');
    await tap(tester, 'setup.cardLater');
    await tap(tester, 'setup.biometricLater');
    await tap(tester, 'setup.notifyDays.plus');
    expect(find.text('4 días'), findsOneWidget);
    await tap(tester, 'setup.notificationsOn');
    expect(key('home.root'), findsOneWidget);
    expect(find.textContaining('Sin permiso'), findsOneWidget);
  });

  group('reminders', () {
    testWidgets('archiving a card cancels its reminders', (tester) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      final card = await seedCard(db, user.id!, cutDay: 31);
      await start(tester);
      expect(
        notifications.scheduled.map((n) => n.id),
        contains(notificationId(card.id!, ReminderKind.cut)),
      );

      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/cards/${card.id}/edit');
      await tester.pumpAndSettle();
      await tap(tester, 'cardForm.archive');
      await tap(tester, 'cardForm.archiveConfirm');
      expect(notifications.scheduled, isEmpty);
    });

    testWidgets('opening locked keeps them (only a logout cancels)', (
      tester,
    ) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      await db.db.update('users', {'biometric_enabled': 1});
      await start(tester, biometrics: FakeBiometricService(succeeds: false));
      expect(key('unlock.root'), findsOneWidget);
      expect(notifications.cancels, 0);
    });

    testWidgets('a reload that leaves the plan as it was does not '
        'reschedule', (tester) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      await seedCard(db, user.id!, cutDay: 31);
      await start(tester);
      expect(notifications.replaces, 1);
      // A theme change reloads the finance snapshot; the plan is the same.
      await tap(tester, 'home.avatar');
      await tap(tester, 'profile.theme.dark');
      expect(notifications.replaces, 1);
      // A new notice period changes it.
      await tap(tester, 'profile.notifyDays.plus');
      expect(notifications.replaces, 2);
    });

    testWidgets('logout cancels them all', (tester) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      await seedCard(db, user.id!, cutDay: 31);
      await start(tester);
      expect(notifications.scheduled, isNotEmpty);

      await tap(tester, 'home.avatar');
      await tap(tester, 'profile.logout');
      await tap(tester, 'profile.logoutConfirm');
      expect(notifications.scheduled, isEmpty);
    });

    testWidgets('tapping one opens its screen', (tester) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      final debt = await DebtsRepository(db).create(
        Debt(
          userId: user.id!,
          creditor: 'Juan',
          amountCents: 50000,
          currency: Currency.dop,
          dueDate: DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 10),
        ),
      );
      await start(tester);
      notifications.tap('/home/debts/${debt.id}');
      await tester.pumpAndSettle();
      expect(key('debtDetail.root'), findsOneWidget);
    });

    testWidgets('one that opened the app waits for the unlock', (tester) async {
      final user = await seedUser(db);
      store.values['session_user_id'] = '${user.id}';
      final card = await seedCard(db, user.id!);
      final bio = FakeBiometricService();
      notifications.launchRoute = '/home/cards/${card.id}';
      // Biometrics on: the app opens locked.
      await db.db.update('users', {'biometric_enabled': 1});
      bio.succeeds = false;
      await start(tester, biometrics: bio);
      expect(key('unlock.root'), findsOneWidget);
      expect(key('cardDetail.root'), findsNothing);

      bio.succeeds = true;
      await tap(tester, 'unlock.biometric');
      expect(key('cardDetail.root'), findsOneWidget);
    });
  });

  group('responsive (rule #2)', () {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('wizard, 4 steps: ${c.name}, ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final user = await pendingUser();
          await start(tester, prefs: {'setup_pending_user': user.id!});
          for (final next in [
            'setup.next',
            'setup.cardLater',
            'setup.biometricLater',
          ]) {
            expect(tester.takeException(), isNull);
            await tap(tester, next);
          }
          expect(tester.takeException(), isNull);
          expect(stepLabel(tester), 'Paso 4 de 4');
        });
      }
    }
  });
}
