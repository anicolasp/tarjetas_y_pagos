import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/test_db.dart';

/// Rule #2: every auth screen renders without overflow on small phones,
/// landscape, tablets and text x2, in light and dark.
void main() {
  late AppDatabase db;

  setUp(() async => db = await openTestDatabase());
  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  /// A registered user with biometrics on, so login shows the fingerprint
  /// button and the unlock screen can be reached.
  Future<int> seedUser() async {
    SharedPreferences.setMockInitialValues({});
    final repo = AuthRepository(
      db,
      testHasher,
      LoginThrottle(await SharedPreferences.getInstance()),
    );
    final user = await repo.register(
      firstName: 'María José',
      lastName: 'Pérez Rodríguez',
      email: 'maria.jose@example.com',
      password: 'abc12345',
    );
    await db.db.update('users', {'biometric_enabled': 1});
    return user.id!;
  }

  final screens = <String, Future<void> Function(WidgetTester)>{
    'onboarding': (tester) async {
      await tester.pumpWidget(
        testApp(await testOverrides(database: Future.value(db))),
      );
      await tester.pumpAndSettle();
      expect(key('onboarding.root'), findsOneWidget);
    },
    'login with fingerprint': (tester) async {
      final id = await seedUser();
      final store = InMemorySecureStore()..values['last_user_id'] = '$id';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
            biometrics: FakeBiometricService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key('login.biometric'), findsOneWidget);
    },
    'register': (tester) async {
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(key('login.register'));
      await tester.tap(key('login.register'));
      await tester.pumpAndSettle();
      expect(key('register.root'), findsOneWidget);
    },
    'unlock': (tester) async {
      final id = await seedUser();
      final store = InMemorySecureStore()..values['session_user_id'] = '$id';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
            biometrics: FakeBiometricService(succeeds: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key('unlock.root'), findsOneWidget);
    },
    'home': (tester) async {
      final id = await seedUser();
      // Without biometrics the saved session opens home directly.
      await db.db.update('users', {'biometric_enabled': 0});
      final store = InMemorySecureStore()..values['session_user_id'] = '$id';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key('home.root'), findsOneWidget);
    },
  };

  for (final MapEntry(key: screen, value: open) in screens.entries) {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('$screen: ${c.name}, ${brightness.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          await open(tester);

          // Overflow errors fail the test through tester.takeException.
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
