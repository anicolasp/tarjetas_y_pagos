import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/greeting.dart';
import 'package:tarjetas_y_pagos/core/language.dart';
import 'package:tarjetas_y_pagos/core/validators.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/data/models/expense.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';
import 'package:tarjetas_y_pagos/l10n/l10n.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// Home, cards, expenses, scan and categories in English and French (#28).
/// Stored data (base categories, merchants) stays as saved; only what the
/// app writes is translated. Fictitious data.
void main() {
  group('texts without a screen', () {
    test('the 13 base categories are translated; own ones are not', () {
      final en = l10nFor(AppLanguage.en);
      final fr = l10nFor(AppLanguage.fr);
      final es = l10nFor(AppLanguage.es);
      Category base(String name) =>
          Category(name: name, icon: 'more_horiz', color: 0xFF000000);
      for (final c in baseCategories) {
        expect(es.categoryLabel(base(c.name)), c.name);
        // A missing translation would fall back to the Spanish name.
        expect(en.categoryLabel(base(c.name)), isNot(c.name));
        expect(fr.categoryLabel(base(c.name)), isNotEmpty);
      }
      expect(en.categoryLabel(base('Supermercado')), 'Supermarket');
      expect(fr.categoryLabel(base('Otros')), 'Autres');
      // A user category named like a base one keeps what the user wrote.
      final own = Category(
        userId: 1,
        name: 'Salud',
        icon: 'pets',
        color: 0xFF000000,
      );
      expect(en.categoryLabel(own), 'Salud');
    });

    test('categories sort by their shown name, "Otros" last', () {
      Category base(String name) =>
          Category(name: name, icon: 'more_horiz', color: 0xFF000000);
      final list = [
        base('Otros'),
        base('Combustible'),
        base('Luz'),
        base('Agua'),
        Category(userId: 1, name: 'Mascotas', icon: 'pets', color: 0),
      ];
      String names(AppLanguage language) {
        final l = l10nFor(language);
        return l.sortedCategories(list).map(l.categoryLabel).join(', ');
      }

      expect(names(AppLanguage.es), 'Agua, Combustible, Luz, Mascotas, Otros');
      expect(
        names(AppLanguage.en),
        'Electricity, Fuel, Mascotas, Water, Other',
      );
      // Accents do not push "Électricité" after the Z's.
      expect(
        names(AppLanguage.fr),
        'Carburant, Eau, Électricité, Mascotas, Autres',
      );
    });

    test('day counts agree in number, 0 included', () {
      expect(l10nFor(AppLanguage.fr).daysCountPlain(0), '0 jour');
      expect(l10nFor(AppLanguage.en).daysCountPlain(0), '0 days');
      expect(l10nFor(AppLanguage.es).daysCountPlain(1), '1 día');
      expect(
        l10nFor(AppLanguage.en)
            .recommendationLine('Closes today', '1 Nov', '1 day'),
        'Closes today · pay by 1 Nov · 1 day',
      );
    });

    test('greetings in every language', () {
      expect(
        l10nFor(AppLanguage.en).greeting(DayPart.morning, 'Ana'),
        'Good morning, Ana',
      );
      expect(
        l10nFor(AppLanguage.fr).greeting(DayPart.night, 'Ana'),
        'Bonsoir, Ana',
      );
      expect(
        l10nFor(AppLanguage.es).greeting(DayPart.afternoon, 'Ana'),
        'Buenas tardes, Ana',
      );
    });

    test('every repository error has a message in every language', () {
      for (final language in AppLanguage.values) {
        final l = l10nFor(language);
        for (final error in FieldError.values) {
          expect(l.fieldError(error), isNotEmpty, reason: '$language $error');
        }
      }
    });
  });

  group('screens', () {
    late AppDatabase db;

    setUpAll(initializeDateFormatting);
    setUp(() async => db = await openTestDatabase());
    tearDown(() async {
      Intl.defaultLocale = appLocale;
      await db.close();
    });

    Finder key(String k) => find.byKey(ValueKey(k));

    /// A user in [language] with a card and an expense saved while the
    /// app was in Spanish.
    Future<({int cardId, int expenseId})> seed(String language) async {
      final user = await seedUser(db);
      await db.db.update('users', {'language': language});
      final card = await seedCard(db, user.id!, alias: 'Gastos de la casa');
      final expense = await seedExpense(
        db,
        user.id!,
        card.id!,
        'Supermercado',
        'Supermercado Nacional',
        date: DateTime(2026, 10, 20),
      );
      return (cardId: card.id!, expenseId: expense.id!);
    }

    Future<void> open(
      WidgetTester tester,
      String language,
      String location,
    ) async {
      final ids = await seed(language);
      final store = InMemorySecureStore()..values['session_user_id'] = '1';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
            now: DateTime(2026, 10, 25, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final path = location
          .replaceAll(':card', '${ids.cardId}')
          .replaceAll(':expense', '${ids.expenseId}');
      if (path != '/home') {
        GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('Home in English', (tester) async {
      await open(tester, 'en', '/home');
      expect(find.textContaining('Good morning'), findsOneWidget);
      expect(find.text('My cards'), findsWidgets);
      expect(find.text('Mis tarjetas'), findsNothing);
    });

    testWidgets('an expense saved in Spanish shows in French', (tester) async {
      await open(tester, 'fr', '/home/cards/:card');
      // The base category is translated; the merchant stays as written.
      expect(find.textContaining('Supermarché'), findsWidgets);
      expect(find.text('Supermercado Nacional'), findsOneWidget);
      expect(find.textContaining('Supermercado ·'), findsNothing);
    });

    testWidgets('expense form in English, base categories translated', (
      tester,
    ) async {
      await open(tester, 'en', '/home/expenses/:expense');
      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.text('Merchant'), findsOneWidget);
      expect(
        find.descendant(
          of: key('expenseForm.category.Supermercado'),
          matching: find.text('Supermarket'),
        ),
        findsOneWidget,
      );
      expect(find.text('Delete expense'), findsOneWidget);
    });

    test('repository rules come as codes, worded in the language', () async {
      final ids = await seed('fr');
      final repo = ExpensesRepository(
        db,
        clock: () => DateTime(2026, 10, 25, 10),
      );
      final category = (await repo.categories(1)).first;
      final future = Expense(
        userId: 1,
        cardId: ids.cardId,
        categoryId: category.id!,
        merchant: 'Colmado Ficticio',
        amountCents: 50000,
        currency: .dop,
        date: DateTime(2026, 12, 1),
        createdAt: DateTime(2026, 10, 25),
      );
      await expectLater(
        repo.create(future),
        throwsA(
          isA<FieldErrorException>().having(
            (e) => e.error,
            'error',
            FieldError.dateInFuture,
          ),
        ),
      );
      final es = l10nFor(AppLanguage.es).fieldError(FieldError.dateInFuture);
      final fr = l10nFor(AppLanguage.fr).fieldError(FieldError.dateInFuture);
      expect(fr, isNot(es));
    });

    testWidgets('a new category cannot look like a base one as shown', (
      tester,
    ) async {
      await open(tester, 'en', '/home/profile/categories/new');
      await tester.enterText(key('categoryForm.name'), 'fuel');
      await tester.tap(key('categoryForm.save'));
      await tester.pumpAndSettle();
      expect(
        find.text('You already have a category like that'),
        findsOneWidget,
      );
      expect(
        await db.db.query('categories', where: 'user_id IS NOT NULL'),
        isEmpty,
      );
    });

    testWidgets('categories in French: included ones translated', (
      tester,
    ) async {
      await open(tester, 'fr', '/home/profile/categories');
      expect(find.text('Incluses'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Supermarché'), 200);
      expect(find.text('Supermarché'), findsOneWidget);
    });

    // Rule #2: the longer English and French texts must fit too.
    final screens = <String, ({String location, String root})>{
      'home': (location: '/home', root: 'home.root'),
      'cards': (location: '/home/cards', root: 'cards.root'),
      'card detail': (location: '/home/cards/:card', root: 'cardDetail.root'),
      'new card': (location: '/home/cards/new', root: 'cardForm.root'),
      'payment form': (
        location: '/home/cards/:card/pay',
        root: 'paymentForm.root',
      ),
      'edit expense': (
        location: '/home/expenses/:expense',
        root: 'expenseForm.root',
      ),
      'categories': (
        location: '/home/profile/categories',
        root: 'categories.root',
      ),
      'new category': (
        location: '/home/profile/categories/new',
        root: 'categoryForm.root',
      ),
    };

    for (final language in ['en', 'fr']) {
      for (final MapEntry(key: name, value: s) in screens.entries) {
        for (final c in responsiveCases) {
          testWidgets('$language $name: ${c.name}', (tester) async {
            setScreen(tester, c.size, c.textScale);
            await open(tester, language, s.location);
            expect(tester.takeException(), isNull);
            expect(key(s.root), findsOneWidget);
          });
        }
      }
      for (final c in responsiveCases) {
        testWidgets('$language filter sheet: ${c.name}', (tester) async {
          setScreen(tester, c.size, c.textScale);
          await open(tester, language, '/home/cards/:card');
          await tester.tap(key('cardDetail.filter'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(key('expenseFilter.root'), findsOneWidget);
        });
      }
    }
  });
}
