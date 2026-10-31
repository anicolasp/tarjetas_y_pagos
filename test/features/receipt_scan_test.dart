import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/core/language.dart';
import 'package:tarjetas_y_pagos/core/money.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/repositories/expenses_repository.dart';
import 'package:tarjetas_y_pagos/l10n/l10n.dart';
import 'package:tarjetas_y_pagos/services/receipt_ai_service.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// "Escanear factura (IA)" in the expense form, with a fake service (no
/// camera, no network). Today is 22 Oct 2026.
void main() {
  final today = DateTime(2026, 10, 22, 10);
  late AppDatabase db;
  late int userId;
  late int cardId;
  late int supermercado;
  late FakeReceiptAiService ai;

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
    cardId = (await seedCard(db, userId, alias: 'Pesos')).id!;
    final categories = await ExpensesRepository(db).categories(userId);
    supermercado = categories.firstWhere((c) => c.name == 'Supermercado').id!;
    ai = FakeReceiptAiService(
      ReceiptScanRead(
        ReceiptData(
          merchant: 'Supermercado Ficticio',
          amountCents: 123450,
          currency: Currency.dop,
          date: DateTime(2026, 10, 20),
          categoryId: supermercado,
        ),
      ),
    );
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> open(
    WidgetTester tester, {
    String apiKey = 'sk-ant-test',
    String? path,
  }) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: today,
          anthropicApiKey: apiKey,
          receiptAi: ai,
        ),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push(path ?? '/home/expenses/new?cardId=$cardId');
    await tester.pumpAndSettle();
  }

  Future<void> scanFrom(WidgetTester tester, String option) async {
    await tester.ensureVisible(key('expenseForm.scanReceipt'));
    await tester.tap(key('expenseForm.scanReceipt'));
    await tester.pumpAndSettle();
    await tester.tap(key('expenseForm.scanReceipt.$option'));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String k) => tester
      .widget<EditableText>(
        find.descendant(of: key(k), matching: find.byType(EditableText)),
      )
      .controller
      .text;

  Future<void> save(WidgetTester tester) async {
    // A focused field scrolls itself back into view when the layout
    // changes (the snackbar), hiding the button again.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(key('expenseForm.save'));
    await tester.pumpAndSettle();
    await tester.tap(key('expenseForm.save'));
    await tester.pumpAndSettle();
  }

  testWidgets('without a key the button is not shown', (tester) async {
    await open(tester, apiKey: '');
    expect(key('expenseForm.root'), findsOneWidget);
    expect(key('expenseForm.scanReceipt'), findsNothing);
  });

  testWidgets('not offered when editing an expense', (tester) async {
    final e = await seedExpense(db, userId, cardId, 'Otros', 'Algo');
    await open(tester, path: '/home/expenses/${e.id}');
    expect(key('expenseForm.delete'), findsOneWidget);
    expect(key('expenseForm.scanReceipt'), findsNothing);
  });

  testWidgets('scan fills every field with the "IA" chip; saved as ia', (
    tester,
  ) async {
    await open(tester);
    await scanFrom(tester, 'gallery');

    expect(ai.sources, [ImageSource.gallery]);
    expect(ai.categories!.map((c) => c.name), contains('Otros'));
    expect(fieldText(tester, 'expenseForm.merchant'), 'Supermercado Ficticio');
    expect(fieldText(tester, 'expenseForm.amount'), '1234.50');
    expect(find.text(formatDate(DateTime(2026, 10, 20))), findsOneWidget);
    for (final f in ['merchant', 'amount', 'currency', 'date', 'category']) {
      expect(key('expenseForm.ai.$f'), findsOneWidget, reason: f);
    }

    await save(tester);
    final row = (await db.db.query('expenses')).single;
    expect(row['merchant'], 'Supermercado Ficticio');
    expect(row['amount_cents'], 123450);
    expect(row['currency'], 'DOP');
    expect(row['category_id'], supermercado);
    expect(row['source'], 'ia');
    expect(DateTime.parse(row['date']! as String), DateTime(2026, 10, 20));
  });

  testWidgets('a US\$ receipt on a RD\$ card asks for the rate', (
    tester,
  ) async {
    ai.result = const ReceiptScanRead(
      ReceiptData(
        merchant: 'Tienda',
        amountCents: 4000,
        currency: Currency.usd,
      ),
    );
    await open(tester);
    await scanFrom(tester, 'camera');
    expect(ai.sources, [ImageSource.camera]);
    expect(key('expenseForm.rate'), findsOneWidget);
    expect(key('expenseForm.ai.currency'), findsOneWidget);
    // Nothing read for the date or the category: no chip, defaults kept.
    expect(key('expenseForm.ai.date'), findsNothing);
    expect(key('expenseForm.ai.category'), findsNothing);
    expect(find.text(formatDate(today)), findsOneWidget);
  });

  testWidgets('editing a field removes its chip', (tester) async {
    await open(tester);
    await scanFrom(tester, 'gallery');
    await tester.enterText(key('expenseForm.merchant'), 'Otro comercio');
    await tester.pump();
    expect(key('expenseForm.ai.merchant'), findsNothing);
    expect(key('expenseForm.ai.amount'), findsOneWidget);

    await tester.ensureVisible(key('expenseForm.category.Otros'));
    await tester.tap(key('expenseForm.category.Otros'));
    await tester.pump();
    expect(key('expenseForm.ai.category'), findsNothing);
  });

  testWidgets('an error shows its message and the form stays usable', (
    tester,
  ) async {
    ai.result = const ReceiptScanFailed(ReceiptScanError.offline);
    await open(tester);
    await scanFrom(tester, 'gallery');
    expect(
      find.text(
        l10nFor(AppLanguage.es).receiptScanError(ReceiptScanError.offline),
      ),
      findsOneWidget,
    );
    expect(key('expenseForm.scanning'), findsNothing);
    // The snackbar goes away on its own (it covers the bottom meanwhile).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(key('expenseForm.merchant'), 'A mano');
    await tester.ensureVisible(key('expenseForm.category.Otros'));
    await tester.tap(key('expenseForm.category.Otros'));
    await tester.enterText(key('expenseForm.amount'), '500');
    await save(tester);
    final row = (await db.db.query('expenses')).single;
    expect(row['merchant'], 'A mano');
    expect(row['source'], 'manual');
  });

  testWidgets('replacing everything the scan read saves it as manual', (
    tester,
  ) async {
    ai.result = const ReceiptScanRead(
      ReceiptData(merchant: 'Leído', amountCents: 1000),
    );
    await open(tester);
    await scanFrom(tester, 'gallery');
    await tester.enterText(key('expenseForm.merchant'), 'Escrito');
    await tester.enterText(key('expenseForm.amount'), '20');
    await tester.ensureVisible(key('expenseForm.category.Otros'));
    await tester.tap(key('expenseForm.category.Otros'));
    await save(tester);
    expect((await db.db.query('expenses')).single['source'], 'manual');
  });

  testWidgets('a second scan keeps the chips of what it did not read', (
    tester,
  ) async {
    await open(tester);
    await scanFrom(tester, 'gallery');
    ai.result = const ReceiptScanRead(ReceiptData(merchant: 'Segunda'));
    await scanFrom(tester, 'gallery');
    expect(fieldText(tester, 'expenseForm.merchant'), 'Segunda');
    expect(fieldText(tester, 'expenseForm.amount'), '1234.50');
    expect(key('expenseForm.ai.merchant'), findsOneWidget);
    expect(key('expenseForm.ai.amount'), findsOneWidget);
  });

  testWidgets('every error has a message the user can read', (tester) async {
    for (final language in AppLanguage.values) {
      final l = l10nFor(language);
      for (final error in ReceiptScanError.values) {
        expect(l.receiptScanError(error), isNotEmpty);
      }
    }
  });

  testWidgets('cancelling changes nothing', (tester) async {
    ai.result = const ReceiptScanCancelled();
    await open(tester);
    await scanFrom(tester, 'camera');
    expect(find.byType(SnackBar), findsNothing);
    expect(fieldText(tester, 'expenseForm.merchant'), isEmpty);
  });

  testWidgets('denied permission explains it and opens the settings', (
    tester,
  ) async {
    ai.result = const ReceiptScanPermissionDenied(ImageSource.camera);
    await open(tester);
    await scanFrom(tester, 'camera');
    expect(key('expenseForm.permissionDialog'), findsOneWidget);
    expect(find.textContaining('leer la factura con la IA'), findsOneWidget);
    await tester.tap(key('expenseForm.openSettings'));
    await tester.pumpAndSettle();
    expect(ai.settingsOpened, 1);
  });

  testWidgets('the overlay shows only while reading', (tester) async {
    ai.gate = Completer<void>();
    await open(tester);
    await tester.ensureVisible(key('expenseForm.scanReceipt'));
    await tester.tap(key('expenseForm.scanReceipt'));
    await tester.pumpAndSettle();
    await tester.tap(key('expenseForm.scanReceipt.gallery'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(key('expenseForm.scanning'), findsOneWidget);
    expect(find.text('Leyendo factura…'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(key('expenseForm.scanReceipt')).onPressed,
      isNull,
    );
    ai.gate!.complete();
    await tester.pumpAndSettle();
    expect(key('expenseForm.scanning'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(key('expenseForm.scanReceipt')).onPressed,
      isNotNull,
    );
  });

  testWidgets('no overlay while answering the permission', (tester) async {
    ai
      ..result = const ReceiptScanPermissionDenied(ImageSource.camera)
      ..gate = Completer<void>();
    await open(tester);
    await tester.ensureVisible(key('expenseForm.scanReceipt'));
    await tester.tap(key('expenseForm.scanReceipt'));
    await tester.pumpAndSettle();
    await tester.tap(key('expenseForm.scanReceipt.camera'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(key('expenseForm.scanning'), findsNothing);
    ai.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('opening a new expense discards lost photos', (tester) async {
    await open(tester);
    expect(ai.lostDiscarded, 1);
  });

  group('responsive (rule #2)', () {
    for (final c in responsiveCases) {
      for (final brightness in Brightness.values) {
        testWidgets('form after a scan: ${c.name}, ${brightness.name}', (
          tester,
        ) async {
          setScreen(tester, c.size, c.textScale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await open(tester);
          await scanFrom(tester, 'gallery');
          expect(tester.takeException(), isNull);
          expect(key('expenseForm.ai.merchant'), findsOneWidget);
        });
      }

      testWidgets('source sheet: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        await open(tester);
        await tester.ensureVisible(key('expenseForm.scanReceipt'));
        await tester.tap(key('expenseForm.scanReceipt'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(key('expenseForm.scanReceipt.gallery'), findsOneWidget);
      });

      testWidgets('permission dialog: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        ai.result = const ReceiptScanPermissionDenied(ImageSource.gallery);
        await open(tester);
        await scanFrom(tester, 'gallery');
        expect(tester.takeException(), isNull);
        expect(key('expenseForm.openSettings'), findsOneWidget);
      });

      testWidgets('reading overlay: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        ai.gate = Completer<void>();
        await open(tester);
        await tester.ensureVisible(key('expenseForm.scanReceipt'));
        await tester.tap(key('expenseForm.scanReceipt'));
        await tester.pumpAndSettle();
        await tester.tap(key('expenseForm.scanReceipt.gallery'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(key('expenseForm.scanning'), findsOneWidget);
        ai.gate!.complete();
        await tester.pumpAndSettle();
      });
    }
  });
}
