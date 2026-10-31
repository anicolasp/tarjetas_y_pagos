import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Choosing the app language (#26): Español / English / Français, applied
/// at once, kept per user and before login. Fictitious data.
void main() {
  late AppDatabase db;
  late AppUser user;
  late InMemorySecureStore store;

  setUpAll(initializeDateFormatting);

  setUp(() async {
    db = await openTestDatabase();
    user = await seedUser(db);
    store = InMemorySecureStore()..values['session_user_id'] = '${user.id}';
  });

  tearDown(() async {
    Intl.defaultLocale = appLocale;
    await db.close();
  });

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(
    WidgetTester tester, {
    String? path,
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
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  Future<void> setLanguage(String code) =>
      db.db.update('users', {'language': code});

  Future<String> storedLanguage() async =>
      (await db.db.query(
            'users',
            where: 'id = ?',
            whereArgs: [user.id],
          )).single['language']
          as String;

  testWidgets('existing users stay in Spanish', (tester) async {
    await start(tester, path: '/home/profile');
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(key('profile.language.es')).selected,
      isTrue,
    );
  });

  testWidgets('E2E 1–4: English at once, then French, kept after a '
      'restart and before login', (tester) async {
    await start(tester, path: '/home/profile');
    await tap(tester, 'profile.language.en');
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(await storedLanguage(), 'en');

    // 2. Logout: the login screen keeps English.
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    expect(find.text('Log in to see your cards and expenses'), findsOneWidget);

    // 3. Back in, French.
    await tester.enterText(key('login.email'), 'maria.jose@example.com');
    await tester.enterText(key('login.password'), 'abc12345');
    await tap(tester, 'login.submit');
    await tap(tester, 'home.avatar');
    await tap(tester, 'profile.language.fr');
    expect(find.text('Mon profil'), findsOneWidget);

    // 4. Close and open the app: still French.
    await tester.pumpWidget(const SizedBox());
    await start(tester, path: '/home/profile');
    expect(find.text('Mon profil'), findsOneWidget);
    expect(await storedLanguage(), 'fr');
  });

  testWidgets('registering on an English screen creates an English user', (
    tester,
  ) async {
    store.values.clear();
    await start(tester, prefs: {'last_language': 'en'});
    await tap(tester, 'login.register');
    await tester.enterText(key('register.firstName'), 'Luis');
    await tester.enterText(key('register.lastName'), 'Ficticio');
    await tester.enterText(key('register.email'), 'luis@example.com');
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await tap(tester, 'register.submit');
    // The setup wizard that follows stays in English.
    expect(find.text('Set up your account'), findsOneWidget);
    final row = (await db.db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['luis@example.com'],
    )).single;
    expect(row['language'], 'en');
  });

  testWidgets('dates follow the language; money keeps its format', (
    tester,
  ) async {
    await setLanguage('en');
    await start(tester);
    expect(formatDate(DateTime(2026, 10, 25)), '25 Oct 2026');
    expect(formatMonthName(DateTime(2026, 10)), 'October');
    expect(formatMoney(125000, .dop), r'RD$ 1,250.00');
  });

  testWidgets('dates are in the language from the first frame', (tester) async {
    // Home is not translated yet (#28) and does not depend on the locale,
    // so it must not be built before the date locale is set.
    await setLanguage('fr');
    await start(tester);
    expect(find.textContaining('octobre'), findsOneWidget);
  });

  testWidgets('screens already open switch their dates too', (tester) async {
    await start(tester);
    expect(find.textContaining('octubre'), findsOneWidget);
    await tap(tester, 'home.avatar');
    await tap(tester, 'profile.language.fr');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('octobre'), findsOneWidget);
  });

  testWidgets('validation messages follow the language', (tester) async {
    store.values.clear();
    await start(tester, prefs: {'last_language': 'en'});
    await tap(tester, 'login.submit');
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('the setup wizard in French', (tester) async {
    await setLanguage('fr');
    await start(tester, prefs: {'setup_pending_user': user.id!});
    expect(find.text('Étape 1 sur 4'), findsOneWidget);
    expect(find.text('Configurez votre compte'), findsOneWidget);
  });

  testWidgets('a rule broken in the repository shows in the language', (
    tester,
  ) async {
    await setLanguage('en');
    await start(tester, path: '/home/profile/password');
    await tester.enterText(key('changePassword.current'), 'abc12345');
    await tester.enterText(key('changePassword.new'), 'abc12345');
    await tester.enterText(key('changePassword.confirm'), 'abc12345');
    await tap(tester, 'changePassword.save');
    expect(find.text('Must be different from the current one'), findsOneWidget);
  });

  group('responsive (rule #2) in English and French', () {
    for (final language in ['en', 'fr']) {
      for (final c in responsiveCases) {
        for (final (name, path, root) in [
          ('profile', '/home/profile', 'profile.root'),
          ('edit name', '/home/profile/name', 'editName.root'),
          ('change email', '/home/profile/email', 'changeEmail.root'),
          ('change password', '/home/profile/password', 'changePassword.root'),
        ]) {
          testWidgets('$language $name: ${c.name}', (tester) async {
            setScreen(tester, c.size, c.textScale);
            await setLanguage(language);
            await start(tester, path: path);
            expect(tester.takeException(), isNull);
            expect(key(root), findsOneWidget);
          });
        }

        testWidgets('$language login and register: ${c.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          store.values.clear();
          await start(tester, prefs: {'last_language': language});
          expect(tester.takeException(), isNull);
          expect(key('login.root'), findsOneWidget);
          await tap(tester, 'login.register');
          expect(tester.takeException(), isNull);
          expect(key('register.root'), findsOneWidget);
        });

        testWidgets('$language onboarding: ${c.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          store.values.clear();
          await tester.pumpWidget(
            testApp(
              await testOverrides(
                database: Future.value(db),
                prefs: {'last_language': language},
                secureStore: store,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(key('onboarding.root'), findsOneWidget);
        });

        testWidgets('$language unlock: ${c.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          await setLanguage(language);
          await db.db.update('users', {'biometric_enabled': 1});
          await start(
            tester,
            biometrics: FakeBiometricService(succeeds: false),
          );
          expect(tester.takeException(), isNull);
          expect(key('unlock.root'), findsOneWidget);
        });

        testWidgets('$language setup wizard, 4 steps: ${c.name}', (
          tester,
        ) async {
          setScreen(tester, c.size, c.textScale);
          await setLanguage(language);
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
          expect(key('setup.root'), findsOneWidget);
        });
      }
    }
  });
}
