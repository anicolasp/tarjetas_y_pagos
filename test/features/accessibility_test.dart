import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/accessibility.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/theme.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Text size, legible font, bold and high contrast (#38) through the real
/// app. The user password is "abc12345". Emails are fictitious.
void main() {
  late AppDatabase db;
  late AppUser user;
  late InMemorySecureStore store;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    user = await seedUser(db);
    store = InMemorySecureStore()..values['session_user_id'] = '${user.id}';
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> setA11y(A11ySettings a11y) async => AuthRepository(
    db,
    testHasher,
    LoginThrottle(await SharedPreferences.getInstance()),
  ).updatePreferences(user.id!, a11y: a11y);

  Future<void> start(
    WidgetTester tester, {
    String? path = '/home/profile',
    Map<String, Object> prefs = const {},
  }) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true, ...prefs},
          secureStore: store,
          now: DateTime(2026, 10, 25, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (path != null) {
      GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.scrollUntilVisible(
      key(k),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  BuildContext screen(WidgetTester tester, String root) =>
      tester.element(key(root));

  String? fontOf(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.fontFamily;

  testWidgets('each setting applies to the whole app at once and is saved', (
    tester,
  ) async {
    await start(tester);
    var context = screen(tester, 'profile.root');
    expect(MediaQuery.textScalerOf(context).scale(10), 10);
    expect(MediaQuery.boldTextOf(context), isFalse);
    expect(fontOf(context), isNot(legibleFontFamily));
    final normalPrimary = Theme.of(context).colorScheme.primary;

    await tap(tester, 'profile.textSize.xlarge');
    context = screen(tester, 'profile.root');
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(15, 1e-9));

    await tap(tester, 'profile.legibleFont');
    expect(fontOf(screen(tester, 'profile.root')), legibleFontFamily);

    await tap(tester, 'profile.boldText');
    expect(MediaQuery.boldTextOf(screen(tester, 'profile.root')), isTrue);

    await tap(tester, 'profile.highContrast');
    context = screen(tester, 'profile.root');
    expect(
      Theme.of(context).colorScheme.primary,
      buildTheme(Brightness.light, highContrast: true).colorScheme.primary,
    );
    expect(Theme.of(context).colorScheme.primary, isNot(normalPrimary));
    expect(tester.takeException(), isNull);

    const all = A11ySettings(
      textSize: TextSize.xlarge,
      legibleFont: true,
      boldText: true,
      highContrast: true,
    );
    final saved = await AuthRepository(
      db,
      testHasher,
      LoginThrottle(await SharedPreferences.getInstance()),
    ).getById(user.id!);
    expect(saved!.a11y, all);
    final prefs = await SharedPreferences.getInstance();
    expect(A11ySettings.decode(prefs.getString('last_a11y')), all);

    // Other screens get them too.
    GoRouter.of(context).go('/home');
    await tester.pumpAndSettle();
    final home = screen(tester, 'home.root');
    expect(MediaQuery.boldTextOf(home), isTrue);
    expect(fontOf(home), legibleFontFamily);

    // Back to the defaults.
    GoRouter.of(home).push('/home/profile');
    await tester.pumpAndSettle();
    await tap(tester, 'profile.textSize.normal');
    await tap(tester, 'profile.legibleFont');
    await tap(tester, 'profile.boldText');
    await tap(tester, 'profile.highContrast');
    context = screen(tester, 'profile.root');
    expect(MediaQuery.textScalerOf(context).scale(10), 10);
    expect(MediaQuery.boldTextOf(context), isFalse);
    expect(fontOf(context), isNot(legibleFontFamily));
    expect(Theme.of(context).colorScheme.primary, normalPrimary);
  });

  testWidgets('the preview shows a sample amount', (tester) async {
    await start(tester);
    await tester.scrollUntilVisible(
      key('profile.a11yPreview'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: key('profile.a11yPreview'),
        matching: find.text('Gastado este mes'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reopening the app keeps them', (tester) async {
    await setA11y(const A11ySettings(textSize: TextSize.large, boldText: true));
    await start(tester, path: null);
    final home = screen(tester, 'home.root');
    expect(MediaQuery.boldTextOf(home), isTrue);
    expect(MediaQuery.textScalerOf(home).scale(10), closeTo(12.5, 1e-9));
  });

  testWidgets('after logout, the login uses the same ones', (tester) async {
    await start(tester);
    await tap(tester, 'profile.textSize.large');
    await tap(tester, 'profile.boldText');
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    final login = screen(tester, 'login.root');
    expect(MediaQuery.boldTextOf(login), isTrue);
    expect(MediaQuery.textScalerOf(login).scale(10), closeTo(12.5, 1e-9));
  });

  testWidgets('before login, the last user settings apply', (tester) async {
    store.values.remove('session_user_id');
    await start(
      tester,
      path: null,
      prefs: {
        'last_a11y': const A11ySettings(
          textSize: TextSize.xlarge,
          legibleFont: true,
          highContrast: true,
        ).encode(),
      },
    );
    final login = screen(tester, 'login.root');
    expect(MediaQuery.textScalerOf(login).scale(10), closeTo(15, 1e-9));
    expect(fontOf(login), legibleFontFamily);
  });

  testWidgets("the phone's bold text wins over the app's", (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(boldText: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await start(tester);
    expect(MediaQuery.boldTextOf(screen(tester, 'profile.root')), isTrue);
  });

  testWidgets('at x3, Home shortcuts take one column and Reports tabs '
      'scroll instead of fading', (tester) async {
    setScreen(tester, const Size(360, 640), 2);
    await setA11y(const A11ySettings(textSize: TextSize.xlarge));
    await start(tester, path: null);
    final cards = tester.getTopLeft(key('home.quick.cards'));
    final expense = tester.getTopLeft(key('home.quick.expense'));
    expect(expense.dx, cards.dx);
    expect(expense.dy, greaterThan(cards.dy));

    GoRouter.of(screen(tester, 'home.root')).push('/home/reports');
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('at normal size, Home keeps two columns and fixed tabs', (
    tester,
  ) async {
    setScreen(tester, const Size(360, 640), 1);
    await start(tester, path: null);
    final cards = tester.getTopLeft(key('home.quick.cards'));
    final expense = tester.getTopLeft(key('home.quick.expense'));
    expect(expense.dy, cards.dy);
    GoRouter.of(screen(tester, 'home.root')).push('/home/reports');
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);
  });

  group('high contrast meets AA (text 4.5:1)', () {
    for (final brightness in Brightness.values) {
      for (final (name, path, root) in [
        ('profile', '/home/profile', 'profile.root'),
        ('home', null, 'home.root'),
        ('debts', '/home/debts', 'debts.root'),
      ]) {
        testWidgets('$name, ${brightness.name}', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await setA11y(const A11ySettings(highContrast: true));
          await start(tester, path: path);
          expect(key(root), findsOneWidget);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        });
      }
    }
  });

  group('responsive at the largest size (x3, legible, bold)', () {
    const biggest = A11ySettings(
      textSize: TextSize.xlarge,
      legibleFont: true,
      boldText: true,
    );
    // Phone x2 by "Muy grande" = the x3 cap.
    const cases = <({String name, Size size, double textScale})>[
      (name: 'phone, text x2', size: Size(360, 640), textScale: 2),
      (name: 'small phone', size: Size(320, 568), textScale: 1),
      (name: 'phone landscape, text x2', size: Size(640, 360), textScale: 2),
    ];
    for (final c in cases) {
      for (final contrast in [false, true]) {
        for (final brightness in Brightness.values) {
          final label =
              '${c.name}, ${brightness.name}'
              '${contrast ? ', high contrast' : ''}';
          for (final (name, path, root) in [
            ('home', null, 'home.root'),
            ('card detail', 'card', 'cardDetail.root'),
            ('reports', '/home/reports', 'reports.root'),
            ('debts', '/home/debts', 'debts.root'),
            ('profile', '/home/profile', 'profile.root'),
            ('login', 'login', 'login.root'),
          ]) {
            testWidgets('$name: $label', (tester) async {
              setScreen(tester, c.size, c.textScale);
              tester.platformDispatcher.platformBrightnessTestValue =
                  brightness;
              addTearDown(
                tester.platformDispatcher.clearPlatformBrightnessTestValue,
              );
              final card = await seedCard(
                db,
                user.id!,
                alias: 'Tarjeta con alias largo',
                limitCents: 15000000,
              );
              await seedExpense(
                db,
                user.id!,
                card.id!,
                'Supermercado',
                'Supermercado Nacional',
                cents: 1250000,
                date: DateTime(2026, 10, 20),
              );
              await setA11y(biggest.copyWith(highContrast: contrast));
              if (path == 'login') store.values.remove('session_user_id');
              await start(
                tester,
                path: switch (path) {
                  'card' => '/home/cards/${card.id}',
                  'login' => null,
                  _ => path,
                },
                prefs: {
                  'last_a11y': biggest
                      .copyWith(highContrast: contrast)
                      .encode(),
                },
              );
              expect(tester.takeException(), isNull);
              expect(key(root), findsOneWidget);
            });
          }
        }
      }
    }
  });
}
