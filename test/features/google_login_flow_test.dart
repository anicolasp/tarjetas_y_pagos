import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/services/google_auth_service.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// "Continuar con Google" through the real app (#37). Google's sheet is a
/// fake; accounts are fictitious.
void main() {
  late AppDatabase db;
  late InMemorySecureStore store;
  late FakeGoogleAuthService google;

  const ana = (sub: 'g-ana', email: 'ana@example.com', name: 'Ana Prueba');

  setUpAll(initializeDateFormatting);

  setUp(() async {
    db = await openTestDatabase();
    store = InMemorySecureStore();
    google = FakeGoogleAuthService(available: true, next: ana);
  });

  tearDown(() async {
    Intl.defaultLocale = appLocale;
    await db.close();
  });

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(WidgetTester tester, {Map<String, Object>? prefs}) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: prefs ?? {'onboarding_seen': true},
          secureStore: store,
          google: google,
          now: DateTime(2026, 10, 25, 10),
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

  Future<void> openProfile(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push('/home/profile');
    await tester.pumpAndSettle();
  }

  testWidgets('without a Google client id the button is hidden', (
    tester,
  ) async {
    google.available = false;
    await start(tester);
    expect(key('login.google'), findsNothing);
  });

  testWidgets('E2E 1: a new Google account goes to the setup wizard', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Continuar con Google'), findsOneWidget);
    await tap(tester, 'login.google');
    expect(key('setup.root'), findsOneWidget);
    final row = (await db.db.query('users')).single;
    expect(row['google_sub'], 'g-ana');
    expect(row['first_name'], 'Ana');
  });

  testWidgets('also from the register screen', (tester) async {
    await start(tester);
    await tap(tester, 'login.register');
    await tap(tester, 'register.google');
    expect(key('setup.root'), findsOneWidget);
  });

  testWidgets('E2E 2: after logout, Google signs in to the same account', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'login.google');
    await tap(tester, 'setup.skip');
    await openProfile(tester);
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    expect(google.signOuts, 1);

    await tap(tester, 'login.google');
    expect(key('home.root'), findsOneWidget);
    expect(await db.db.query('users'), hasLength(1));
  });

  testWidgets('a Google-only account typing a password is pointed to '
      'Google', (tester) async {
    await start(tester);
    await tap(tester, 'login.google');
    await tap(tester, 'setup.skip');
    await openProfile(tester);
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    await tester.enterText(key('login.email'), 'ana@example.com');
    await tester.enterText(key('login.password'), 'abc12345');
    await tap(tester, 'login.submit');
    expect(
      find.text(
        'Esta cuenta se creó con Google: entra con "Continuar con Google".',
      ),
      findsOneWidget,
    );
  });

  testWidgets('logging out of an account without Google never opens it', (
    tester,
  ) async {
    await seedUser(db, email: 'ana@example.com');
    store.values['session_user_id'] = '1';
    await start(tester);
    await openProfile(tester);
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    expect(key('login.root'), findsOneWidget);
    expect(google.signOuts, 0);
  });

  testWidgets('closing Google\'s sheet does nothing', (tester) async {
    google.next = null;
    await start(tester);
    await tap(tester, 'login.google');
    expect(key('login.root'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('E2E 4: no connection explains it; the password still works', (
    tester,
  ) async {
    google.failure = GoogleSignInFailure.failed;
    await start(tester);
    await tap(tester, 'login.google');
    expect(
      find.text(
        'No se pudo iniciar con Google. Revisa tu conexión e inténtalo de '
        'nuevo.',
      ),
      findsOneWidget,
    );
    expect(key('login.submit'), findsOneWidget);
  });

  testWidgets('a misconfigured app says so', (tester) async {
    google.failure = GoogleSignInFailure.misconfigured;
    await start(tester);
    await tap(tester, 'login.google');
    expect(
      find.text(
        'El inicio con Google no está disponible en esta versión de la app.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('E2E 3: an existing account is linked with its password', (
    tester,
  ) async {
    await seedUser(db, email: 'ana@example.com');
    await start(tester);
    await tap(tester, 'login.google');
    expect(key('googleLink.dialog'), findsOneWidget);
    expect(find.textContaining('ana@example.com'), findsOneWidget);

    await tester.enterText(key('googleLink.password'), 'mala1234');
    await tap(tester, 'googleLink.confirm');
    expect(find.text('Contraseña incorrecta'), findsOneWidget);
    expect((await db.db.query('users')).single['google_sub'], isNull);

    await tester.enterText(key('googleLink.password'), 'abc12345');
    await tap(tester, 'googleLink.confirm');
    expect(key('home.root'), findsOneWidget);
    expect((await db.db.query('users')).single['google_sub'], 'g-ana');
  });

  group('Mi perfil', () {
    testWidgets('a Google-only account sets a password first', (tester) async {
      await start(tester);
      await tap(tester, 'login.google');
      await tap(tester, 'setup.skip');
      await openProfile(tester);
      expect(key('profile.google'), findsOneWidget);
      expect(key('profile.googleUnlink'), findsNothing);
      expect(key('profile.changePassword'), findsNothing);
      expect(key('profile.changeEmail'), findsNothing);
      expect(key('profile.securityQuestion'), findsNothing);

      await tap(tester, 'profile.setPassword');
      await tester.enterText(key('setPassword.new'), 'nueva2026');
      await tester.enterText(key('setPassword.confirm'), 'nueva2026');
      await tap(tester, 'setPassword.save');
      expect(find.text('Contraseña creada'), findsOneWidget);
      // With a password, everything that needs one is back.
      expect(key('profile.changePassword'), findsOneWidget);
      expect(key('profile.securityQuestion'), findsOneWidget);
      expect(key('profile.googleUnlink'), findsOneWidget);
    });

    testWidgets('unlinking asks for the password', (tester) async {
      await seedUser(db, email: 'ana@example.com');
      await db.db.update('users', {'google_sub': 'g-ana'});
      store.values['session_user_id'] = '1';
      await start(tester);
      await openProfile(tester);
      await tap(tester, 'profile.googleUnlink');
      await tester.enterText(key('googleUnlink.password'), 'mala1234');
      await tap(tester, 'googleUnlink.confirm');
      expect(find.text('Contraseña incorrecta'), findsOneWidget);

      await tester.enterText(key('googleUnlink.password'), 'abc12345');
      await tap(tester, 'googleUnlink.confirm');
      expect(find.text('Google desvinculado'), findsOneWidget);
      expect(key('profile.google'), findsNothing);
      expect((await db.db.query('users')).single['google_sub'], isNull);
    });
  });

  testWidgets('in English', (tester) async {
    await start(
      tester,
      prefs: {'onboarding_seen': true, 'last_language': 'en'},
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
  });

  // Rule #2: login with the button, the link dialog and the Google-only
  // profile, in every size, both themes and the three languages.
  for (final language in ['es', 'en', 'fr']) {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('$language ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await seedUser(db, email: 'ana@example.com');
          await db.db.update('users', {'language': language});
          await start(
            tester,
            prefs: {'onboarding_seen': true, 'last_language': language},
          );
          await tester.ensureVisible(key('login.google'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tap(tester, 'login.google');
          expect(tester.takeException(), isNull);
          expect(key('googleLink.dialog'), findsOneWidget);
        });
      }
    }
  }
}
