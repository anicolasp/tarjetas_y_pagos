import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/data/database.dart';

import '../helpers/fakes.dart';
import '../helpers/test_db.dart';

/// End-to-end auth flows through the real app, router, repository and an
/// in-memory database. Only platform services are faked.
void main() {
  late AppDatabase db;
  late InMemorySecureStore secureStore;

  setUp(() async {
    db = await openTestDatabase();
    secureStore = InMemorySecureStore();
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> start(
    WidgetTester tester, {
    bool onboardingSeen = true,
    FakeBiometricService? biometrics,
  }) async {
    final overrides = await testOverrides(
      database: Future.value(db),
      prefs: {if (onboardingSeen) 'onboarding_seen': true},
      secureStore: secureStore,
      biometrics: biometrics,
    );
    await tester.pumpWidget(testApp(overrides));
    await tester.pumpAndSettle();
  }

  Future<void> register(
    WidgetTester tester, {
    String email = 'ana@example.com',
  }) async {
    await tester.tap(key('login.register'));
    await tester.pumpAndSettle();
    await tester.enterText(key('register.firstName'), 'Ana');
    await tester.enterText(key('register.lastName'), 'Prueba');
    await tester.enterText(key('register.email'), email);
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await tester.ensureVisible(key('register.submit'));
    await tester.tap(key('register.submit'));
    await tester.pumpAndSettle();
  }

  /// Logout lives in the profile, reached from the home avatar.
  Future<void> logout(WidgetTester tester) async {
    await tester.tap(key('home.avatar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(key('profile.logout'));
    await tester.pumpAndSettle();
    await tester.tap(key('profile.logout'));
    await tester.pumpAndSettle();
    await tester.tap(key('profile.logoutConfirm'));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String email, String password) async {
    await tester.enterText(key('login.email'), email);
    await tester.enterText(key('login.password'), password);
    await tester.tap(key('login.submit'));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch: slides, then login', (tester) async {
    await start(tester, onboardingSeen: false);
    expect(key('onboarding.root'), findsOneWidget);
    expect(find.text('Tus tarjetas'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(key('onboarding.next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Reportes'), findsOneWidget);
    await tester.tap(key('onboarding.start'));
    await tester.pumpAndSettle();

    expect(key('login.root'), findsOneWidget);
  });

  testWidgets('skip goes straight to login', (tester) async {
    await start(tester, onboardingSeen: false);
    await tester.tap(key('onboarding.skip'));
    await tester.pumpAndSettle();
    expect(key('login.root'), findsOneWidget);
  });

  testWidgets('register enters the app and remembers the session', (
    tester,
  ) async {
    await start(tester);
    await register(tester);
    expect(key('home.root'), findsOneWidget);
    expect(find.textContaining(', Ana'), findsOneWidget);
    expect(secureStore.values['session_user_id'], isNotNull);

    // Reopen the app: straight to home, no slides, no login.
    await tester.pumpWidget(const SizedBox());
    await start(tester);
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('register shows inline errors', (tester) async {
    await start(tester);
    await tester.tap(key('login.register'));
    await tester.pumpAndSettle();
    await tester.enterText(key('register.email'), 'no-es-correo');
    await tester.enterText(key('register.password'), 'abcdefgh');
    await tester.enterText(key('register.confirm'), 'otra');
    await tester.ensureVisible(key('register.submit'));
    await tester.tap(key('register.submit'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.text('Debe tener letras y números'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(key('register.root'), findsOneWidget);
  });

  testWidgets('register with an existing email shows the error', (
    tester,
  ) async {
    await start(tester);
    await register(tester);
    await logout(tester);

    await register(tester, email: 'ANA@example.com');
    expect(find.text('Este correo ya está registrado'), findsOneWidget);
    expect(key('register.root'), findsOneWidget);
  });

  testWidgets('logout, wrong password, then right password', (tester) async {
    await start(tester);
    await register(tester);
    await logout(tester);
    expect(key('login.root'), findsOneWidget);
    expect(secureStore.values['session_user_id'], isNull);

    await login(tester, 'ana@example.com', 'mala1234');
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(key('login.root'), findsOneWidget);

    await login(tester, 'ana@example.com', 'abc12345');
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('5 wrong passwords show the wait message', (tester) async {
    await start(tester);
    await register(tester);
    await logout(tester);

    for (var i = 0; i < 5; i++) {
      await login(tester, 'ana@example.com', 'mala1234');
    }
    expect(
      find.text('Demasiados intentos. Intenta de nuevo en 30 s.'),
      findsOneWidget,
    );
  });

  group('biometrics', () {
    Future<void> enableBiometrics() async {
      await db.db.update('users', {'biometric_enabled': 1});
    }

    testWidgets('a saved session asks for the fingerprint', (tester) async {
      final bio = FakeBiometricService();
      await start(tester, biometrics: bio);
      await register(tester);
      await enableBiometrics();

      await tester.pumpWidget(const SizedBox());
      await start(tester, biometrics: bio);

      // The prompt opens automatically and succeeds.
      expect(bio.prompts, 1);
      expect(key('home.root'), findsOneWidget);
    });

    testWidgets('failed fingerprint can fall back to the password', (
      tester,
    ) async {
      final bio = FakeBiometricService(succeeds: false);
      await start(tester, biometrics: bio);
      await register(tester);
      await enableBiometrics();

      await tester.pumpWidget(const SizedBox());
      await start(tester, biometrics: bio);
      expect(key('unlock.root'), findsOneWidget);
      expect(find.text('Hola, Ana'), findsOneWidget);

      await tester.tap(key('unlock.usePassword'));
      await tester.pumpAndSettle();
      expect(key('login.root'), findsOneWidget);
      // Last user is prefilled and offered biometric login.
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(key('login.biometric'), findsOneWidget);
    });

    testWidgets('after logout, fingerprint logs in the last user', (
      tester,
    ) async {
      final bio = FakeBiometricService();
      await start(tester, biometrics: bio);
      await register(tester);
      await enableBiometrics();
      // Reload so the in-memory user picks up biometric_enabled.
      await tester.pumpWidget(const SizedBox());
      await start(tester, biometrics: bio);

      await logout(tester);
      await tester.tap(key('login.biometric'));
      await tester.pumpAndSettle();
      expect(key('home.root'), findsOneWidget);
    });

    testWidgets('no fingerprint button without biometrics enabled', (
      tester,
    ) async {
      await start(tester, biometrics: FakeBiometricService());
      await register(tester);
      await logout(tester);
      expect(key('login.biometric'), findsNothing);
    });

    testWidgets('biometrics on but no fingerprints left: asks for password', (
      tester,
    ) async {
      final bio = FakeBiometricService();
      await start(tester, biometrics: bio);
      await register(tester);
      await enableBiometrics();

      bio.available = false;
      await tester.pumpWidget(const SizedBox());
      await start(tester, biometrics: bio);

      expect(key('login.root'), findsOneWidget);
      expect(key('home.root'), findsNothing);
      expect(secureStore.values['session_user_id'], isNull);
    });

    testWidgets('"Usar contraseña" wins over a late fingerprint', (
      tester,
    ) async {
      final bio = FakeBiometricService();
      await start(tester, biometrics: bio);
      await register(tester);
      await enableBiometrics();

      bio.pending = Completer<bool>();
      await tester.pumpWidget(const SizedBox());
      await start(tester, biometrics: bio);
      expect(key('unlock.root'), findsOneWidget);

      await tester.tap(key('unlock.usePassword'));
      await tester.pumpAndSettle();
      bio.pending!.complete(true);
      await tester.pumpAndSettle();

      expect(key('login.root'), findsOneWidget);
      expect(secureStore.values['session_user_id'], isNull);
    });
  });

  testWidgets('unreadable secure storage goes to login, not a stuck splash', (
    tester,
  ) async {
    secureStore = BrokenSecureStore();
    await start(tester);
    expect(key('login.root'), findsOneWidget);
  });
}
