import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/language.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/core/notification_plan.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/finance_snapshot.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/data/models/debt.dart';
import 'package:tarjetas_y_pagos/data/models/debt_payment.dart';
import 'package:tarjetas_y_pagos/data/repositories/debts_repository.dart';
import 'package:tarjetas_y_pagos/features/notifications/reminders.dart';
import 'package:tarjetas_y_pagos/l10n/l10n.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Debts, reports and reminders in English and French (#29). Creditors,
/// descriptions and merchants stay as the user wrote them. Fictitious data.
void main() {
  setUpAll(initializeDateFormatting);

  group('reminders', () {
    final now = DateTime(2026, 10, 22, 8);
    final card = CreditCard(
      id: 1,
      userId: 1,
      alias: 'Visa Oro',
      bank: 'Banco Ficticio',
      brand: CardBrand.visa,
      last4: '1234',
      cutDay: 5,
      paymentDays: 20,
      currency: Currency.dop,
      color: 0,
      createdAt: DateTime(2026),
    );
    final debt = Debt(
      id: 1,
      userId: 1,
      creditor: 'Juan',
      amountCents: 50000,
      currency: Currency.dop,
      dueDate: DateTime(2026, 11, 20),
      createdAt: DateTime(2026, 9),
    );

    List<String> bodies(AppLanguage language, {int days = 3}) =>
        planNotifications(
          FinanceSnapshot(
            cards: [card],
            expenses: const [],
            payments: const [],
            debts: [debt],
            debtPayments: const <DebtPayment>[],
          ),
          now: now,
          daysBefore: days,
          texts: L10nReminderTexts(l10nFor(language), language.code),
        ).map((n) => n.body).toList();

    test('in English and French, with their own dates', () {
      expect(bodies(AppLanguage.en), [
        'Your card Visa Oro closes in 3 days',
        'Your debt with Juan is due on 20 Nov 2026',
      ]);
      expect(bodies(AppLanguage.fr), [
        'Votre carte Visa Oro clôture dans 3 jours',
        'Votre dette envers Juan arrive à échéance le 20 nov. 2026',
      ]);
    });

    test('today and tomorrow are words, in every language', () {
      expect(bodies(AppLanguage.en, days: 1).first, contains('tomorrow'));
      expect(bodies(AppLanguage.fr, days: 0).first, contains("aujourd'hui"));
      expect(bodies(AppLanguage.es, days: 1).first, contains('mañana'));
    });
  });

  group('screens', () {
    late AppDatabase db;
    late FakeNotificationService notifications;

    setUp(() async {
      db = await openTestDatabase();
      notifications = FakeNotificationService();
    });
    tearDown(() async {
      Intl.defaultLocale = appLocale;
      await db.close();
    });

    Finder key(String k) => find.byKey(ValueKey(k));

    /// A user in [language] with a card that owes, an expense, and a
    /// debt with a payment, all saved while the app was in Spanish.
    Future<int> seed(String language) async {
      final user = await seedUser(db);
      await db.db.update('users', {'language': language});
      final card = await seedCard(db, user.id!, alias: 'Gastos de la casa');
      await seedExpense(
        db,
        user.id!,
        card.id!,
        'Supermercado',
        'Supermercado Nacional',
        date: DateTime(2026, 10, 20),
      );
      final repo = DebtsRepository(db, clock: () => DateTime(2026, 10, 25));
      final debt = await repo.create(
        Debt(
          userId: user.id!,
          creditor: 'Préstamo de Juan',
          description: 'Para la nevera',
          amountCents: 300000,
          currency: Currency.dop,
          dueDate: DateTime(2026, 12, 15),
          createdAt: DateTime(2026, 10, 1),
        ),
      );
      await repo.addPayment(
        user.id!,
        DebtPayment(
          debtId: debt.id!,
          amountCents: 100000,
          date: DateTime(2026, 10, 10),
        ),
      );
      return debt.id!;
    }

    Future<void> open(
      WidgetTester tester,
      String language,
      String location,
    ) async {
      final debtId = await seed(language);
      final store = InMemorySecureStore()..values['session_user_id'] = '1';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
            notifications: notifications,
            now: DateTime(2026, 10, 25, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final path = location.replaceAll(':debt', '$debtId');
      if (path != '/home') {
        GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('a new language rewrites the reminders: same ids and times', (
      tester,
    ) async {
      await open(tester, 'es', '/home/profile');
      final before = notifications.scheduled;
      expect(before, isNotEmpty);
      expect(before.first.body, startsWith('Tu tarjeta'));
      expect(notifications.channel?.name, 'Recordatorios');

      await tester.ensureVisible(key('profile.language.en'));
      await tester.tap(key('profile.language.en'));
      await tester.pumpAndSettle();

      final after = notifications.scheduled;
      expect(after.map((n) => (n.id, n.at, n.route)), [
        for (final n in before) (n.id, n.at, n.route),
      ]);
      expect(after.first.body, startsWith('Your card'));
      expect(
        after.map((n) => n.body),
        contains('Your debt with Préstamo de Juan is due on 15 Dec 2026'),
      );
      expect(notifications.channel?.name, 'Reminders');
    });

    testWidgets('debts in English; the creditor stays as written', (
      tester,
    ) async {
      await open(tester, 'en', '/home/debts');
      expect(find.text('Debts'), findsOneWidget);
      expect(find.text('Other debts'), findsOneWidget);
      expect(find.text('Préstamo de Juan'), findsOneWidget);
      expect(find.text(r'RD$ 2,000.00 left'), findsOneWidget);
      expect(find.text('33% paid'), findsOneWidget);
    });

    testWidgets('debt detail in French', (tester) async {
      await open(tester, 'fr', '/home/debts/:debt');
      expect(find.text('Dette'), findsOneWidget);
      expect(find.text('Remboursements'), findsOneWidget);
      expect(find.text('Enregistrer un remboursement'), findsOneWidget);
    });

    testWidgets('reports in French: periods, totals and base categories', (
      tester,
    ) async {
      await open(tester, 'fr', '/home/reports');
      expect(find.text('Rapports'), findsOneWidget);
      expect(find.text('Ce mois-ci'), findsOneWidget);
      expect(find.text(r'Dépenses en RD$'), findsOneWidget);
      expect(find.text('Supermarché'), findsOneWidget);
      expect(find.text('Supermercado'), findsNothing);
    });

    // Rule #2: the longer English and French texts must fit too.
    final screens = <String, ({String location, String root})>{
      'debts': (location: '/home/debts', root: 'debts.root'),
      'debt detail': (location: '/home/debts/:debt', root: 'debtDetail.root'),
      'edit debt': (location: '/home/debts/:debt/edit', root: 'debtForm.root'),
      'debt payment': (
        location: '/home/debts/:debt/pay',
        root: 'debtPayment.root',
      ),
      'reports': (location: '/home/reports', root: 'reports.root'),
    };

    for (final language in ['en', 'fr']) {
      for (final MapEntry(key: name, value: s) in screens.entries) {
        for (final c in responsiveCases) {
          for (final brightness in Brightness.values) {
            testWidgets('$language $name: ${c.name}, ${brightness.name}', (
              tester,
            ) async {
              setScreen(tester, c.size, c.textScale);
              tester.platformDispatcher.platformBrightnessTestValue =
                  brightness;
              addTearDown(
                tester.platformDispatcher.clearPlatformBrightnessTestValue,
              );
              await open(tester, language, s.location);
              expect(tester.takeException(), isNull);
              expect(key(s.root), findsOneWidget);
            });
          }
        }
      }
    }
  });
}
