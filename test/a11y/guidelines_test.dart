import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/repositories/debts_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Every screen meets Flutter's accessibility guidelines (#40): labeled
/// tap targets, 48 dp targets and text contrast, in light and dark. Data
/// is fictitious; the password is "abc12345".
void main() {
  late AppDatabase db;
  late AppUser user;
  late InMemorySecureStore store;
  late int cardId;
  late int expenseId;
  late int debtId;
  late int categoryId;
  final today = DateTime(2026, 10, 25, 10);

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    user = await seedUser(db);
    store = InMemorySecureStore()..values['session_user_id'] = '${user.id}';
    final card = await seedCard(
      db,
      user.id!,
      alias: 'Gastos de la casa',
      limitCents: 15000000,
    );
    cardId = card.id!;
    expenseId = (await seedExpense(
      db,
      user.id!,
      cardId,
      'Supermercado',
      'Supermercado Ficticio',
      cents: 125000,
      date: DateTime(2026, 10, 20),
    )).id!;
    await seedExpense(
      db,
      user.id!,
      cardId,
      'Combustible',
      'Estación Ficticia',
      cents: 80000,
      date: DateTime(2026, 9, 12),
    );
    final debts = DebtsRepository(db, clock: () => today);
    final debt = await debts.create(
      Debt(
        userId: user.id!,
        creditor: 'Préstamo Ficticio',
        amountCents: 1000000,
        currency: Currency.dop,
        dueDate: DateTime(2026, 11, 21),
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    debtId = debt.id!;
    await debts.addPayment(
      user.id!,
      DebtPayment(debtId: debtId, amountCents: 200000, date: today),
    );
    categoryId =
        (await db.db.query(
              'categories',
              where: 'user_id IS NULL',
              limit: 1,
            )).single['id']!
            as int;
  });

  tearDown(() => db.close());

  Future<void> start(
    WidgetTester tester, {
    String? path,
    Map<String, Object> prefs = const {},
    FakeBiometricService? biometrics,
  }) async {
    // Tall enough to lay out (and check) every element of each screen, not
    // only the first 600 dp.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true, ...prefs},
          secureStore: store,
          biometrics: biometrics,
          now: today,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (path != null) {
      GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
      await tester.pumpAndSettle();
    }
  }

  Future<void> meetsAll(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  // Logged in: every route under /home.
  final loggedIn = <(String, String Function())>[
    ('home', () => '/home'),
    ('profile', () => '/home/profile'),
    ('edit name', () => '/home/profile/name'),
    ('change email', () => '/home/profile/email'),
    ('change password', () => '/home/profile/password'),
    ('security question', () => '/home/profile/security-question'),
    ('categories', () => '/home/profile/categories'),
    ('new category', () => '/home/profile/categories/new'),
    ('edit category', () => '/home/profile/categories/$categoryId'),
    ('reports', () => '/home/reports'),
    ('debts', () => '/home/debts'),
    ('new debt', () => '/home/debts/new'),
    ('debt detail', () => '/home/debts/$debtId'),
    ('edit debt', () => '/home/debts/$debtId/edit'),
    ('debt payment', () => '/home/debts/$debtId/pay'),
    ('cards', () => '/home/cards'),
    ('new card', () => '/home/cards/new'),
    ('card detail', () => '/home/cards/$cardId'),
    ('edit card', () => '/home/cards/$cardId/edit'),
    ('card payment', () => '/home/cards/$cardId/pay'),
    ('new expense', () => '/home/expenses/new'),
    ('edit expense', () => '/home/expenses/$expenseId'),
  ];

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      setUp(() {
        TestWidgetsFlutterBinding
                .instance
                .platformDispatcher
                .platformBrightnessTestValue =
            brightness;
      });
      tearDown(
        () => TestWidgetsFlutterBinding.instance.platformDispatcher
            .clearPlatformBrightnessTestValue(),
      );

      for (final (name, path) in loggedIn) {
        testWidgets(name, (tester) async {
          await start(tester, path: path() == '/home' ? null : path());
          expect(tester.takeException(), isNull);
          await meetsAll(tester);
        });
      }

      testWidgets('reports, movements tab', (tester) async {
        await start(tester, path: '/home/reports');
        await tester.tap(find.byKey(const ValueKey('reports.tabList')));
        await tester.pumpAndSettle();
        await meetsAll(tester);
      });

      for (final (name, path) in [
        ('login', null),
        ('register', '/register'),
        ('forgot password', '/forgot-password'),
      ]) {
        testWidgets(name, (tester) async {
          store.values.remove('session_user_id');
          await start(tester);
          if (path != null) {
            GoRouter.of(tester.element(find.byType(Navigator).first)).go(path);
            await tester.pumpAndSettle();
          }
          await meetsAll(tester);
        });
      }

      testWidgets('onboarding', (tester) async {
        store.values.remove('session_user_id');
        await start(tester, prefs: {'onboarding_seen': false});
        await meetsAll(tester);
      });

      testWidgets('unlock', (tester) async {
        await db.db.update('users', {'biometric_enabled': 1});
        await start(tester, biometrics: FakeBiometricService(succeeds: false));
        expect(find.byKey(const ValueKey('unlock.root')), findsOneWidget);
        await meetsAll(tester);
      });

      testWidgets('setup wizard', (tester) async {
        await start(tester, prefs: {'setup_pending_user': user.id!});
        await meetsAll(tester);
      });
    });
  }
}
