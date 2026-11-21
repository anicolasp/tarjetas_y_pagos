import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/accessibility.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// The app's own screen brightness (#39) through the real app. Passwords
/// are "abc12345"; emails are fictitious.
void main() {
  late AppDatabase db;
  late AppUser user;
  late AppUser otra;
  late InMemorySecureStore store;
  late FakeBrightnessService brightness;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    user = await seedUser(db);
    otra = await seedUser(
      db,
      firstName: 'Otra',
      lastName: 'Persona',
      email: 'otra@example.com',
    );
    store = InMemorySecureStore()..values['session_user_id'] = '${user.id}';
    brightness = FakeBrightnessService(systemValue: 0.4);
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<AuthRepository> repo() async => AuthRepository(
    db,
    testHasher,
    LoginThrottle(await SharedPreferences.getInstance()),
  );

  Future<double?> saved(int userId) async =>
      (await (await repo()).getById(userId))!.a11y.brightness;

  Future<void> start(
    WidgetTester tester, {
    bool toProfile = true,
    Map<String, Object> prefs = const {},
  }) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true, ...prefs},
          secureStore: store,
          brightness: brightness,
          now: DateTime(2026, 10, 25, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (toProfile) {
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/profile');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        key('profile.brightnessSystem'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Centered: right after the scroll the slider can sit under the bar.
      await Scrollable.ensureVisible(
        tester.element(key('profile.brightness')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
    }
  }

  Slider slider(WidgetTester tester) =>
      tester.widget<Slider>(key('profile.brightness'));

  testWidgets("by default it follows the phone: box checked, slider off", (
    tester,
  ) async {
    await start(tester);
    expect(
      tester.widget<CheckboxListTile>(key('profile.brightnessSystem')).value,
      isTrue,
    );
    expect(slider(tester).onChanged, isNull);
    expect(brightness.applied, isNull);
    expect(brightness.calls, isNot(contains(startsWith('apply'))));
  });

  testWidgets('unchecking starts from the phone brightness and saves it', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(key('profile.brightnessSystem'));
    await tester.pumpAndSettle();
    expect(brightness.applied, 0.4);
    expect(await saved(user.id!), 0.4);
    expect(slider(tester).onChanged, isNotNull);
    expect(
      find.text(NumberFormat.percentPattern('es').format(0.4)),
      findsOneWidget,
    );
  });

  testWidgets('dragging previews live, saves at the end; never below 10 %', (
    tester,
  ) async {
    await (await repo()).updatePreferences(
      user.id!,
      a11y: const A11ySettings(brightness: 0.5),
    );
    await start(tester);
    expect(brightness.applied, 0.5);

    final gesture = await tester.startGesture(
      tester.getCenter(key('profile.brightness')),
    );
    await gesture.moveBy(const Offset(1000, 0));
    await tester.pump();
    // Shown at once, not saved yet.
    expect(brightness.applied, 1);
    expect(await saved(user.id!), 0.5);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(await saved(user.id!), 1);

    await tester.drag(key('profile.brightness'), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(await saved(user.id!), closeTo(minAppBrightness, 1e-9));
    expect(brightness.applied, closeTo(minAppBrightness, 1e-9));
  });

  testWidgets('checking the box goes back to the phone brightness', (
    tester,
  ) async {
    await (await repo()).updatePreferences(
      user.id!,
      a11y: const A11ySettings(brightness: 0.9),
    );
    await start(tester);
    await tester.tap(key('profile.brightnessSystem'));
    await tester.pumpAndSettle();
    expect(brightness.applied, isNull);
    expect(await saved(user.id!), isNull);
    expect(slider(tester).onChanged, isNull);
  });

  testWidgets('hidden app: the phone brightness; back on screen: the '
      "user's again", (tester) async {
    await (await repo()).updatePreferences(
      user.id!,
      a11y: const A11ySettings(brightness: 0.9),
    );
    await start(tester, toProfile: false);
    expect(brightness.applied, 0.9);

    // The order a phone reports when going to the home screen and back.
    Future<void> go(List<AppLifecycleState> states) async {
      for (final s in states) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
    }

    await go([
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(brightness.applied, isNull);

    await go([
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    expect(brightness.applied, 0.9);
  });

  testWidgets('each user gets their own brightness after logging in', (
    tester,
  ) async {
    final auth = await repo();
    await auth.updatePreferences(
      user.id!,
      a11y: const A11ySettings(brightness: 0.9),
    );
    await auth.updatePreferences(
      otra.id!,
      a11y: const A11ySettings(brightness: 0.3),
    );
    // What the app saved for the screens before login (#38).
    await start(
      tester,
      prefs: {'last_a11y': const A11ySettings(brightness: 0.9).encode()},
    );
    expect(brightness.applied, 0.9);

    await tester.scrollUntilVisible(
      key('profile.logout'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(key('profile.logout'));
    await tester.pumpAndSettle();
    await tester.tap(key('profile.logoutConfirm'));
    await tester.pumpAndSettle();
    // The login keeps the last user's, like the other settings.
    expect(brightness.applied, 0.9);

    await tester.enterText(key('login.email'), 'otra@example.com');
    await tester.enterText(key('login.password'), 'abc12345');
    await tester.tap(key('login.submit'));
    await tester.pumpAndSettle();
    expect(key('home.root'), findsOneWidget);
    expect(brightness.applied, 0.3);
  });

  group('responsive (rule #2)', () {
    for (final c in responsiveCases) {
      for (final b in Brightness.values) {
        testWidgets('${c.name}, ${b.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = b;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await (await repo()).updatePreferences(
            user.id!,
            a11y: const A11ySettings(textSize: TextSize.xlarge, brightness: 1),
          );
          await start(tester);
          expect(tester.takeException(), isNull);
          expect(key('profile.brightness.value'), findsOneWidget);
        });
      }
    }
  });
}
