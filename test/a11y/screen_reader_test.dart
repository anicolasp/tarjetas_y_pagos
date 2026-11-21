import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/features/auth/auth_widgets.dart';
import 'package:tarjetas_y_pagos/features/reports/report_charts.dart';
import 'package:tarjetas_y_pagos/l10n/l10n.dart';

import '../helpers/fakes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// What TalkBack says (#40): amounts in words, one element per card, a
/// spoken summary per chart, and errors announced. Data is fictitious.
void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  group('moneySemantics', () {
    test('pesos and dollars, singular and plural, in each language', () {
      expect(es.moneySemantics(125000, Currency.dop), '1250 pesos dominicanos');
      expect(es.moneySemantics(100, Currency.dop), '1 peso dominicano');
      expect(es.moneySemantics(4200, Currency.usd), '42 dólares');
      expect(en.moneySemantics(125000, Currency.dop), '1250 Dominican pesos');
      expect(en.moneySemantics(100, Currency.usd), '1 US dollar');
      expect(fr.moneySemantics(4200, Currency.usd), '42 dollars américains');
    });

    test('cents and negatives', () {
      expect(
        es.moneySemantics(125050, Currency.dop),
        '1250 pesos dominicanos con 50 centavos',
      );
      expect(en.moneySemantics(101, Currency.usd), '1 US dollar and 1 cent');
      expect(
        es.moneySemantics(-5000, Currency.dop),
        'menos 50 pesos dominicanos',
      );
      expect(es.moneySemantics(0, Currency.dop), '0 pesos dominicanos');
    });

    test('speakMoney replaces every amount in a sentence, any sign', () {
      final sentence = es.debtSplit(
        formatMoney(85000, Currency.dop),
        formatMoney(100000, Currency.dop),
      );
      expect(
        es.speakMoney(sentence),
        es.debtSplit('850 pesos dominicanos', '1000 pesos dominicanos'),
      );
      expect(
        es.speakMoney('−${formatMoney(2550, Currency.usd)}'),
        'menos 25 dólares con 50 centavos',
      );
      expect(es.speakMoney('Supermercado'), isNull);
    });
  });

  group('in the app', () {
    late AppDatabase db;
    late AppUser user;
    late int cardId;
    final today = DateTime(2026, 10, 25, 10);

    setUpAll(() => initializeDateFormatting(appLocale));

    setUp(() async {
      db = await openTestDatabase();
      user = await seedUser(db);
      cardId = (await seedCard(
        db,
        user.id!,
        alias: 'Gastos de la casa',
        last4: '4321',
      )).id!;
      await seedExpense(
        db,
        user.id!,
        cardId,
        'Supermercado',
        'Supermercado Ficticio',
        cents: 125000,
        date: DateTime(2026, 10, 20),
      );
    });

    tearDown(() => db.close());

    Future<void> start(
      WidgetTester tester, {
      String? path,
      bool loggedIn = true,
    }) async {
      // Tall: lists build (and expose) every element, charts included.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 3000);
      addTearDown(tester.view.reset);
      final store = InMemorySecureStore();
      if (loggedIn) store.values['session_user_id'] = '${user.id}';
      await tester.pumpWidget(
        testApp(
          await testOverrides(
            database: Future.value(db),
            prefs: {'onboarding_seen': true},
            secureStore: store,
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

    testWidgets('a card is one element with its name, last 4 and cut', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await start(tester);
      final tile = tester.getSemantics(
        find.byKey(ValueKey('home.carousel.$cardId')),
      );
      expect(tile.label, startsWith('Gastos de la casa, '));
      expect(tile.label, contains('terminada en 4321'));
      expect(tile.label, contains('Corte '));
      expect(tile.label, isNot(contains('•')));
      expect(tile.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('amounts are read in words', (tester) async {
      final semantics = tester.ensureSemantics();
      await start(tester, path: '/home/cards/$cardId');
      // Merged with its row label: "Balance (DOP)" then the amount.
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('cardDetail.balanceValue.DOP')),
            )
            .label,
        contains('1250 pesos dominicanos'),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'RD\$')),
        findsNothing,
        reason: 'no amount is read as "R D dollar"',
      );
      semantics.dispose();
    });

    testWidgets('each chart has a spoken summary', (tester) async {
      final semantics = tester.ensureSemantics();
      await start(tester, path: '/home/reports');
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Gráfico circular por categoría\. '
            r'Supermercado, 1250 pesos dominicanos, 100 %',
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a form with errors announces the first one', (tester) async {
      await start(tester, loggedIn: false);
      await tester.tap(find.byKey(const ValueKey('login.submit')));
      await tester.pumpAndSettle();
      expect(
        tester.takeAnnouncements(),
        contains(
          isAccessibilityAnnouncement(
            es.fieldEmailRequired,
            assertiveness: Assertiveness.assertive,
          ),
        ),
      );
    });
  });

  testWidgets('the month bars read every month with its amount', (
    tester,
  ) async {
    await initializeDateFormatting(appLocale);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MonthBars(
            currency: Currency.dop,
            months: [
              (month: DateTime(2026, 9), totalCents: 80000),
              (month: DateTime(2026, 10), totalCents: 125050),
            ],
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Gráfico de barras por mes. '
        'septiembre 2026, 800 pesos dominicanos; '
        'octubre 2026, 1250 pesos dominicanos con 50 centavos',
      ),
      findsOneWidget,
    );
    // The axis labels ("1.5K", "sept") are not read one by one.
    expect(find.bySemanticsLabel(RegExp(r'^\d+(\.\d+)?K$')), findsNothing);
    semantics.dispose();
  });

  testWidgets('snack bar messages are a live region, amounts in words', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showErrorSnackBar(context, es.passwordUpdated),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    // The node TalkBack announces on its own when it appears.
    expect(
      tester.getSemantics(find.text(es.passwordUpdated)),
      isSemantics(isLiveRegion: true, label: es.passwordUpdated),
    );
    semantics.dispose();
  });
}
