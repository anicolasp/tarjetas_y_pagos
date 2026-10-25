import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/data/repositories/auth_repository.dart';
import 'package:tarjetas_y_pagos/data/repositories/categories_repository.dart';
import 'package:tarjetas_y_pagos/features/auth/auth_controller.dart';
import 'package:tarjetas_y_pagos/services/login_throttle.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Profile, security, theme and categories through the real app. The user
/// password is "abc12345". Emails are fictitious.
void main() {
  late AppDatabase db;
  late AppUser user;
  late InMemorySecureStore store;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    user = await seedUser(db);
    await seedUser(
      db,
      firstName: 'Otra',
      lastName: 'Persona',
      email: 'otra@example.com',
    );
    store = InMemorySecureStore()..values['session_user_id'] = '${user.id}';
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<AuthRepository> authRepo() async => AuthRepository(
    db,
    testHasher,
    LoginThrottle(await SharedPreferences.getInstance()),
  );

  Future<void> start(
    WidgetTester tester, {
    String? path = '/home/profile',
    FakeBiometricService? biometrics,
  }) async {
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
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

  /// Closes the app (disposes every provider) and opens it again.
  Future<void> reopen(WidgetTester tester, {FakeBiometricService? bio}) async {
    await tester.pumpWidget(const SizedBox());
    await start(tester, path: null, biometrics: bio);
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.ensureVisible(key(k));
    await tester.pumpAndSettle();
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }

  ThemeMode appTheme(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  testWidgets('E2E 1: avatar opens the profile with name and email', (
    tester,
  ) async {
    await start(tester, path: null);
    await tap(tester, 'home.avatar');
    expect(key('profile.root'), findsOneWidget);
    expect(find.text('María José Pérez Rodríguez'), findsOneWidget);
    expect(find.text('maria.jose@example.com'), findsOneWidget);
  });

  testWidgets('E2E 2: dark theme applies everywhere and survives a restart', (
    tester,
  ) async {
    await start(tester);
    expect(appTheme(tester), ThemeMode.system);
    await tap(tester, 'profile.theme.dark');
    expect(appTheme(tester), ThemeMode.dark);
    expect(
      Theme.of(tester.element(key('profile.root'))).brightness,
      Brightness.dark,
    );

    await reopen(tester);
    expect(key('home.root'), findsOneWidget);
    expect(appTheme(tester), ThemeMode.dark);
  });

  testWidgets('before login, the last user\'s theme is used', (tester) async {
    await start(tester);
    await tap(tester, 'profile.theme.dark');
    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    expect(key('login.root'), findsOneWidget);
    expect(appTheme(tester), ThemeMode.dark);
  });

  testWidgets('E2E 3: change password: wrong current, then right, then login', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'profile.changePassword');
    await tester.enterText(key('changePassword.current'), 'equivocada1');
    await tester.enterText(key('changePassword.new'), 'nueva2026');
    await tester.enterText(key('changePassword.confirm'), 'nueva2026');
    await tap(tester, 'changePassword.save');
    expect(find.text('La contraseña actual no es correcta'), findsOneWidget);
    expect(key('changePassword.root'), findsOneWidget);

    await tester.enterText(key('changePassword.current'), 'abc12345');
    await tap(tester, 'changePassword.save');
    expect(find.text('Contraseña actualizada'), findsOneWidget);
    expect(key('profile.root'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the snackbar leaves
    await tester.pumpAndSettle();

    await tap(tester, 'profile.logout');
    await tap(tester, 'profile.logoutConfirm');
    await tester.enterText(key('login.email'), 'maria.jose@example.com');
    await tester.enterText(key('login.password'), 'abc12345');
    await tap(tester, 'login.submit');
    expect(key('home.root'), findsNothing); // the old one no longer works
    await tester.enterText(key('login.password'), 'nueva2026');
    await tap(tester, 'login.submit');
    expect(key('home.root'), findsOneWidget);
  });

  testWidgets('an edit that ends after logout does not log back in', (
    tester,
  ) async {
    final bio = FakeBiometricService()..pending = Completer<bool>();
    await start(tester, biometrics: bio);
    final container = ProviderScope.containerOf(
      tester.element(key('profile.root')),
    );
    final auth = container.read(authControllerProvider.notifier);
    // The fingerprint prompt is still open when the logout lands.
    final enabling = auth.enableBiometrics();
    await tester.pump();
    await auth.logout();
    await tester.pumpAndSettle();
    bio.pending!.complete(true);
    await enabling;
    await tester.pumpAndSettle();
    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    expect(key('login.root'), findsOneWidget);
  });

  testWidgets('change email: taken one rejected, a new one works', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'profile.changeEmail');
    await tester.enterText(key('changeEmail.email'), 'OTRA@example.com');
    await tester.enterText(key('changeEmail.current'), 'abc12345');
    await tap(tester, 'changeEmail.save');
    expect(find.text('Ese correo ya tiene una cuenta'), findsOneWidget);

    await tester.enterText(key('changeEmail.email'), 'maria.nueva@example.com');
    await tap(tester, 'changeEmail.save');
    expect(find.text('maria.nueva@example.com'), findsOneWidget);
  });

  testWidgets('edit name updates the profile and the Home greeting', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'profile.editName');
    await tester.enterText(key('editName.first'), 'Ana');
    await tester.enterText(key('editName.last'), 'Ficticia');
    await tap(tester, 'editName.save');
    expect(find.text('Ana Ficticia'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ana'), findsWidgets);
    expect(
      find.descendant(of: key('home.avatar'), matching: find.text('AF')),
      findsOneWidget,
    );
  });

  group('E2E 4: biometrics', () {
    testWidgets('turning it on asks for the fingerprint; then it is needed '
        'to open the app', (tester) async {
      final bio = FakeBiometricService();
      await start(tester, biometrics: bio);
      await tap(tester, 'profile.biometric');
      expect(bio.prompts, 1);
      expect(
        tester.widget<SwitchListTile>(key('profile.biometric')).value,
        isTrue,
      );
      bio.succeeds = false; // so the unlock screen stays open
      await reopen(tester, bio: bio);
      expect(key('unlock.root'), findsOneWidget);
      expect(bio.prompts, 2);
    });

    testWidgets('a failed fingerprint leaves it off', (tester) async {
      await start(tester, biometrics: FakeBiometricService(succeeds: false));
      await tap(tester, 'profile.biometric');
      expect(find.text('No se confirmó la huella.'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(key('profile.biometric')).value,
        isFalse,
      );
    });

    testWidgets('without a fingerprint set up it explains why', (tester) async {
      await start(tester, biometrics: FakeBiometricService(available: false));
      await tap(tester, 'profile.biometric');
      expect(
        find.text('Configura una huella en los ajustes del teléfono primero.'),
        findsOneWidget,
      );
    });

    testWidgets('3 failed fingerprints: only the password is offered', (
      tester,
    ) async {
      await (await authRepo()).updatePreferences(
        user.id!,
        biometricEnabled: true,
      );
      final bio = FakeBiometricService(succeeds: false);
      await start(tester, path: null, biometrics: bio);
      expect(key('unlock.root'), findsOneWidget); // 1st failure on open
      await tap(tester, 'unlock.biometric');
      await tap(tester, 'unlock.biometric');
      expect(key('unlock.biometric'), findsNothing);
      expect(find.text('Entrar con contraseña'), findsOneWidget);
      await tap(tester, 'unlock.usePassword');
      expect(key('login.root'), findsOneWidget);
    });
  });

  testWidgets('default currency and notice days are saved', (tester) async {
    await start(tester);
    await tap(tester, 'profile.currency.USD');
    await tap(tester, 'profile.notifyDays.plus');
    await tap(tester, 'profile.notifyDays.plus');
    expect(find.text('5 días'), findsOneWidget);
    final saved = (await (await authRepo()).getById(user.id!))!;
    expect(saved.defaultCurrency.code, 'USD');
    expect(saved.notifyDaysBefore, 5);
  });

  group('categories', () {
    testWidgets('E2E 5: "Mascotas" shows up in the expense form', (
      tester,
    ) async {
      await seedCard(db, user.id!);
      await start(tester);
      await tap(tester, 'profile.categories');
      expect(key('categories.empty'), findsOneWidget);
      await tap(tester, 'categories.add');
      await tester.enterText(key('categoryForm.name'), 'Mascotas');
      await tap(tester, 'categoryForm.icon.pets');
      await tap(tester, 'categoryForm.color.4');
      await tap(tester, 'categoryForm.save');
      expect(find.text('Mascotas'), findsOneWidget);

      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/home/expenses/new');
      await tester.pumpAndSettle();
      expect(key('expenseForm.category.Mascotas'), findsOneWidget);
    });

    testWidgets('a duplicate name is rejected', (tester) async {
      await start(tester, path: '/home/profile/categories/new');
      await tester.enterText(key('categoryForm.name'), 'supermercado');
      await tap(tester, 'categoryForm.save');
      expect(find.text('Ya tienes una categoría así'), findsOneWidget);
    });

    testWidgets('deleting one with expenses asks where they go', (
      tester,
    ) async {
      final repo = CategoriesRepository(db);
      final cat = await repo.create(
        user.id!,
        const Category(name: 'Mascotas', icon: 'pets', color: 0xFF2E7D32),
      );
      final card = await seedCard(db, user.id!);
      await seedExpense(db, user.id!, card.id!, 'Mascotas', 'Veterinaria');
      await start(tester, path: '/home/profile/categories');
      await tap(tester, 'categories.item.${cat.id}');
      await tap(tester, 'categoryForm.delete');
      expect(key('categoryForm.reassignDialog'), findsOneWidget);
      expect(find.text('"Mascotas" tiene 1 gasto'), findsOneWidget);
      await tap(tester, 'categoryForm.reassignConfirm'); // to "Otros"
      expect(key('categories.root'), findsOneWidget);
      expect(find.text('Mascotas'), findsNothing);
      final otros = (await repo.list(user.id!))
          .firstWhere((c) => c.name == 'Otros')
          .id;
      final row = (await db.db.query('expenses')).single;
      expect(row['category_id'], otros);
    });

    testWidgets('base categories cannot be opened for editing', (tester) async {
      await start(tester, path: '/home/profile/categories');
      final base = find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('categories.item.') &&
            w.onTap == null,
      );
      expect(base, findsWidgets);
    });
  });

  group('responsive (rule #2)', () {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        for (final (name, path, root) in [
          ('profile', '/home/profile', 'profile.root'),
          ('categories', '/home/profile/categories', 'categories.root'),
          (
            'category form',
            '/home/profile/categories/new',
            'categoryForm.root',
          ),
        ]) {
          testWidgets('$name: ${c.name}, ${brightness.name}', (tester) async {
            setScreen(tester, c.size, c.textScale);
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            await CategoriesRepository(db).create(
              user.id!,
              const Category(
                name: 'Categoría con nombre muy largo',
                icon: 'pets',
                color: 0xFF2E7D32,
              ),
            );
            await start(tester, path: path);
            expect(tester.takeException(), isNull);
            expect(key(root), findsOneWidget);
          });
        }
      }

      for (final (name, path, root) in [
        ('edit name', '/home/profile/name', 'editName.root'),
        ('change email', '/home/profile/email', 'changeEmail.root'),
        ('change password', '/home/profile/password', 'changePassword.root'),
      ]) {
        testWidgets('$name: ${c.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          await start(tester, path: path);
          expect(tester.takeException(), isNull);
          expect(key(root), findsOneWidget);
        });
      }

      testWidgets('reassign dialog and logout dialog: ${c.name}', (
        tester,
      ) async {
        setScreen(tester, c.size, c.textScale);
        final cat = await CategoriesRepository(db).create(
          user.id!,
          const Category(name: 'Mascotas', icon: 'pets', color: 0xFF2E7D32),
        );
        final card = await seedCard(db, user.id!);
        await seedExpense(db, user.id!, card.id!, 'Mascotas', 'Veterinaria');
        await start(tester, path: '/home/profile/categories/${cat.id}');
        await tap(tester, 'categoryForm.delete');
        expect(tester.takeException(), isNull);
        expect(key('categoryForm.reassignConfirm'), findsOneWidget);
      });
    }
  });
}
