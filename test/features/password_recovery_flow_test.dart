import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/security_question.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/security.dart';
import '../helpers/test_db.dart';

/// "¿Olvidaste tu contraseña?" through the real app (#27). Fictitious data.
void main() {
  late AppDatabase db;
  late InMemorySecureStore store;

  setUpAll(initializeDateFormatting);

  setUp(() async {
    db = await openTestDatabase();
    store = InMemorySecureStore();
  });

  tearDown(() async {
    Intl.defaultLocale = appLocale;
    await db.close();
  });

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<AuthRepository> repo() async {
    SharedPreferences.setMockInitialValues({});
    return AuthRepository(
      db,
      testHasher,
      LoginThrottle(await SharedPreferences.getInstance()),
    );
  }

  Future<void> seedAna({bool withQuestion = true}) async =>
      (await repo()).register(
        firstName: 'Ana',
        lastName: 'Prueba',
        email: 'ana@example.com',
        password: 'abc12345',
        securityQuestion: withQuestion
            ? const PresetQuestion(SecurityQuestionPreset.birthCity)
            : null,
        securityAnswer: withQuestion ? 'Santo Domingo' : null,
      );

  Future<void> start(
    WidgetTester tester, {
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
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String password) async {
    await tester.enterText(key('login.email'), 'ana@example.com');
    await tester.enterText(key('login.password'), password);
    await tap(tester, 'login.submit');
  }

  testWidgets('E2E 1: registering asks for the question', (tester) async {
    await start(tester);
    await tap(tester, 'login.register');
    await tester.enterText(key('register.firstName'), 'Ana');
    await tester.enterText(key('register.lastName'), 'Prueba');
    await tester.enterText(key('register.email'), 'ana@example.com');
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await tap(tester, 'register.submit');
    expect(find.text('Elige una pregunta'), findsOneWidget);
    expect(find.text('Escribe tu respuesta'), findsOneWidget);
    expect(key('register.root'), findsOneWidget);

    await pickSecurityQuestion(tester, 'register');
    await tap(tester, 'register.submit');
    expect(key('setup.root'), findsOneWidget);
  });

  testWidgets('E2E 2–3: recover, back to the login, old password fails', (
    tester,
  ) async {
    await seedAna();
    await start(tester);
    await tap(tester, 'login.forgot');
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    expect(find.text('¿En qué ciudad naciste?'), findsOneWidget);

    await tester.enterText(key('forgot.answer'), '  SANTO domingo ');
    await tap(tester, 'forgot.next');
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    await tester.enterText(key('forgot.newPassword'), 'nueva2026');
    await tester.enterText(key('forgot.confirm'), 'nueva2026');
    await tap(tester, 'forgot.save');
    expect(key('login.root'), findsOneWidget);
    expect(find.text('Contraseña actualizada'), findsOneWidget);

    await login(tester, 'abc12345');
    expect(key('home.root'), findsNothing);
    await login(tester, 'nueva2026');
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('E2E 4: 5 wrong answers show the wait', (tester) async {
    await seedAna();
    await start(tester);
    await tap(tester, 'login.forgot');
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    for (var i = 0; i < 4; i++) {
      await tester.enterText(key('forgot.answer'), 'Santiago');
      await tap(tester, 'forgot.next');
      expect(find.text('La respuesta no es correcta'), findsOneWidget);
    }
    await tester.enterText(key('forgot.answer'), 'Santiago');
    await tap(tester, 'forgot.next');
    expect(find.textContaining('Demasiados intentos'), findsOneWidget);
  });

  testWidgets('unknown email and accounts without a question', (tester) async {
    await seedAna(withQuestion: false);
    await start(tester);
    await tap(tester, 'login.forgot');
    await tester.enterText(key('forgot.email'), 'nadie@example.com');
    await tap(tester, 'forgot.next');
    expect(
      find.text('No encontramos una cuenta con ese correo'),
      findsOneWidget,
    );
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    expect(
      find.text('Esta cuenta no tiene pregunta de seguridad'),
      findsOneWidget,
    );
  });

  testWidgets('an error on the last step goes back to its step', (
    tester,
  ) async {
    await seedAna();
    await start(tester);
    await tap(tester, 'login.forgot');
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    await tester.enterText(key('forgot.answer'), 'Santo Domingo');
    await tap(tester, 'forgot.next');
    // The account disappears before saving (another session, a restore…).
    await db.db.delete('users');
    await tester.enterText(key('forgot.newPassword'), 'nueva2026');
    await tester.enterText(key('forgot.confirm'), 'nueva2026');
    await tap(tester, 'forgot.save');
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(
      find.text('No encontramos una cuenta con ese correo'),
      findsOneWidget,
    );
  });

  testWidgets('Done on the keyboard submits the registration', (tester) async {
    await start(tester);
    await tap(tester, 'login.register');
    await tester.enterText(key('register.firstName'), 'Ana');
    await tester.enterText(key('register.lastName'), 'Prueba');
    await tester.enterText(key('register.email'), 'ana@example.com');
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await pickSecurityQuestion(tester, 'register');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(key('setup.root'), findsOneWidget);
  });

  testWidgets('back goes to the previous step, then to the login', (
    tester,
  ) async {
    await seedAna();
    await start(tester);
    await tap(tester, 'login.forgot');
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(key('login.root'), findsOneWidget);
  });

  testWidgets('register with my own question', (tester) async {
    await start(tester);
    await tap(tester, 'login.register');
    await tester.enterText(key('register.firstName'), 'Ana');
    await tester.enterText(key('register.lastName'), 'Prueba');
    await tester.enterText(key('register.email'), 'ana@example.com');
    await tester.enterText(key('register.password'), 'abc12345');
    await tester.enterText(key('register.confirm'), 'abc12345');
    await pickSecurityQuestion(tester, 'register', preset: 'custom');
    await tap(tester, 'register.submit');
    expect(find.text('Escribe tu pregunta'), findsOneWidget);
    await tester.enterText(key('register.customQuestion'), '¿Color favorito?');
    await tap(tester, 'register.submit');
    expect(key('setup.root'), findsOneWidget);
    expect(
      await (await repo()).securityQuestionFor('ana@example.com'),
      const CustomQuestion('¿Color favorito?'),
    );
  });

  testWidgets('E2E 5: an account without a question is warned in Mi '
      'perfil and sets one', (tester) async {
    await seedAna(withQuestion: false);
    store.values['session_user_id'] = '1';
    await start(tester);
    await tap(tester, 'home.avatar');
    expect(
      find.text('Configura una pregunta para poder recuperar tu contraseña.'),
      findsOneWidget,
    );
    await tap(tester, 'profile.securityQuestion');
    await pickSecurityQuestion(tester, 'securityQuestion', preset: 'firstPet');
    await tester.enterText(key('securityQuestion.current'), 'abc12345');
    await tap(tester, 'securityQuestion.save');
    expect(key('profile.root'), findsOneWidget);
    expect(find.text('¿Cómo se llamaba tu primera mascota?'), findsOneWidget);
  });

  testWidgets('the recovery in English', (tester) async {
    await seedAna();
    await start(tester, prefs: {'last_language': 'en'});
    await tap(tester, 'login.forgot');
    expect(find.text('Recover password'), findsOneWidget);
    await tester.enterText(key('forgot.email'), 'ana@example.com');
    await tap(tester, 'forgot.next');
    expect(find.text('In what city were you born?'), findsOneWidget);
  });

  group('responsive (rule #2)', () {
    for (final language in ['es', 'en', 'fr']) {
      for (final c in responsiveCases) {
        for (final brightness in Brightness.values) {
          testWidgets('$language recovery, 3 steps: ${c.name}, '
              '${brightness.name}', (tester) async {
            setScreen(tester, c.size, c.textScale);
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            await seedAna();
            await start(tester, prefs: {'last_language': language});
            await tap(tester, 'login.forgot');
            expect(tester.takeException(), isNull);
            await tester.enterText(key('forgot.email'), 'ana@example.com');
            await tap(tester, 'forgot.next');
            expect(tester.takeException(), isNull);
            await tester.enterText(key('forgot.answer'), 'Santo Domingo');
            await tap(tester, 'forgot.next');
            expect(tester.takeException(), isNull);
            expect(key('forgot.newPassword'), findsOneWidget);
          });
        }

        testWidgets('$language register with the question: ${c.name}', (
          tester,
        ) async {
          setScreen(tester, c.size, c.textScale);
          await start(tester, prefs: {'last_language': language});
          await tap(tester, 'login.register');
          await pickSecurityQuestion(tester, 'register', preset: 'custom');
          expect(tester.takeException(), isNull);
          expect(key('register.customQuestion'), findsOneWidget);
        });

        testWidgets('$language profile security question: ${c.name}', (
          tester,
        ) async {
          setScreen(tester, c.size, c.textScale);
          await seedAna(withQuestion: false);
          await db.db.update('users', {'language': language});
          store.values['session_user_id'] = '1';
          await start(tester);
          GoRouter.of(tester.element(find.byType(Navigator).first))
              .push('/home/profile');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tap(tester, 'profile.securityQuestion');
          await pickSecurityQuestion(tester, 'securityQuestion');
          expect(tester.takeException(), isNull);
          expect(key('securityQuestion.root'), findsOneWidget);
        });
      }
    }
  });
}
