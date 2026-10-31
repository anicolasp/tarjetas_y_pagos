import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tarjetas_y_pagos/core/card_detection.dart';
import 'package:tarjetas_y_pagos/core/formatters.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/models/credit_card.dart';
import 'package:tarjetas_y_pagos/services/card_scan_service.dart';

import '../helpers/fakes.dart';
import '../helpers/screen_sizes.dart';
import '../helpers/seed.dart';
import '../helpers/test_db.dart';

/// "Escanear tarjeta" in the card form, with a fake scan service (no
/// camera, no ML Kit). Numbers are public test numbers.
void main() {
  late AppDatabase db;
  late int userId;
  late FakeCardScanService scanner;

  const detected = CardScanDetected(
    CardDetection(last4: '1111', brand: CardBrand.mastercard, bank: 'BHD'),
  );

  setUpAll(() => initializeDateFormatting(appLocale));

  setUp(() async {
    db = await openTestDatabase();
    userId = (await seedUser(db)).id!;
    scanner = FakeCardScanService(detected);
  });

  tearDown(() => db.close());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> open(
    WidgetTester tester, [
    String path = '/home/cards/new',
  ]) async {
    final store = InMemorySecureStore()..values['session_user_id'] = '$userId';
    await tester.pumpWidget(
      testApp(
        await testOverrides(
          database: Future.value(db),
          prefs: {'onboarding_seen': true},
          secureStore: store,
          now: DateTime(2026, 10, 22, 10),
          cardScan: scanner,
        ),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first)).push(path);
    await tester.pumpAndSettle();
  }

  Future<void> scanFrom(WidgetTester tester, String option) async {
    await tester.tap(key('cardForm.scan'));
    await tester.pumpAndSettle();
    await tester.tap(key('cardForm.scan.$option'));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String k) => tester
      .widget<EditableText>(
        find.descendant(of: key(k), matching: find.byType(EditableText)),
      )
      .controller
      .text;

  bool brandSelected(WidgetTester tester, CardBrand b) =>
      tester.widget<ChoiceChip>(key('cardForm.brand.${b.name}')).selected;

  testWidgets('scan from the gallery fills last 4, brand and bank, then save', (
    tester,
  ) async {
    await open(tester);
    await scanFrom(tester, 'gallery');

    expect(scanner.sources, [ImageSource.gallery]);
    expect(fieldText(tester, 'cardForm.last4'), '1111');
    expect(fieldText(tester, 'cardForm.bank'), 'BHD');
    expect(brandSelected(tester, CardBrand.mastercard), isTrue);
    for (final f in ['last4', 'brand', 'bank']) {
      expect(key('cardForm.detected.$f'), findsOneWidget, reason: f);
    }

    await tester.enterText(key('cardForm.alias'), 'Escaneada');
    await tester.enterText(key('cardForm.cutDay'), '15');
    await tester.ensureVisible(key('cardForm.save'));
    await tester.pumpAndSettle();
    await tester.tap(key('cardForm.save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1111'), findsWidgets);
    final rows = await db.db.query('cards');
    expect(rows, hasLength(1));
    expect(rows.single['last4'], '1111');
    expect(rows.single['brand'], 'mastercard');
    // No text column holds more than the last 4 digits.
    for (final value in rows.single.values.whereType<String>()) {
      expect(value, isNot(matches(RegExp(r'\d{5,}'))), reason: value);
    }
  });

  testWidgets('the camera option asks the service for the camera', (
    tester,
  ) async {
    await open(tester);
    await scanFrom(tester, 'camera');
    expect(scanner.sources, [ImageSource.camera]);
  });

  testWidgets('editing a detected field removes its chip', (tester) async {
    await open(tester);
    await scanFrom(tester, 'gallery');

    await tester.enterText(key('cardForm.last4'), '2222');
    await tester.pump();
    expect(key('cardForm.detected.last4'), findsNothing);
    expect(key('cardForm.detected.bank'), findsOneWidget);

    await tester.ensureVisible(key('cardForm.brand.visa'));
    await tester.tap(key('cardForm.brand.visa'));
    await tester.pump();
    expect(key('cardForm.detected.brand'), findsNothing);
  });

  testWidgets('only what was read is filled in', (tester) async {
    scanner.result = const CardScanDetected(CardDetection(bank: 'Qik'));
    await open(tester);
    await scanFrom(tester, 'gallery');

    expect(fieldText(tester, 'cardForm.bank'), 'Qik');
    expect(fieldText(tester, 'cardForm.last4'), isEmpty);
    expect(brandSelected(tester, CardBrand.visa), isTrue); // default kept
    expect(key('cardForm.detected.bank'), findsOneWidget);
    expect(key('cardForm.detected.last4'), findsNothing);
    expect(key('cardForm.detected.brand'), findsNothing);
  });

  testWidgets('nothing read shows the snackbar', (tester) async {
    scanner.result = const CardScanNothing();
    await open(tester);
    await scanFrom(tester, 'gallery');
    expect(
      find.text('No pudimos leer la tarjeta, completa los datos manualmente'),
      findsOneWidget,
    );
    expect(fieldText(tester, 'cardForm.last4'), isEmpty);
  });

  testWidgets('cancelling changes nothing', (tester) async {
    scanner.result = const CardScanCancelled();
    await open(tester);
    await scanFrom(tester, 'camera');
    expect(find.byType(SnackBar), findsNothing);
    expect(key('cardForm.permissionDialog'), findsNothing);
    expect(fieldText(tester, 'cardForm.last4'), isEmpty);
  });

  testWidgets('closing the source sheet does not scan', (tester) async {
    await open(tester);
    await tester.tap(key('cardForm.scan'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // scrim
    await tester.pumpAndSettle();
    expect(scanner.sources, isEmpty);
  });

  testWidgets('camera denied explains why and opens the settings', (
    tester,
  ) async {
    scanner.result = const CardScanPermissionDenied(ImageSource.camera);
    await open(tester);
    await scanFrom(tester, 'camera');

    expect(key('cardForm.permissionDialog'), findsOneWidget);
    await tester.tap(key('cardForm.openSettings'));
    await tester.pumpAndSettle();
    expect(scanner.settingsOpened, 1);
    expect(key('cardForm.permissionDialog'), findsNothing);
  });

  testWidgets('"Ahora no" closes the dialog without opening the settings', (
    tester,
  ) async {
    scanner.result = const CardScanPermissionDenied(ImageSource.camera);
    await open(tester);
    await scanFrom(tester, 'camera');
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(scanner.settingsOpened, 0);
  });

  testWidgets('a loading overlay shows while reading', (tester) async {
    scanner.gate = Completer<void>();
    await open(tester);
    await tester.tap(key('cardForm.scan'));
    await tester.pumpAndSettle();
    await tester.tap(key('cardForm.scan.gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(key('cardForm.scanning'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(key('cardForm.scan')).onPressed,
      isNull,
    );

    scanner.gate!.complete();
    await tester.pumpAndSettle();
    expect(key('cardForm.scanning'), findsNothing);
    expect(fieldText(tester, 'cardForm.last4'), '1111');
  });

  testWidgets('no overlay while choosing or answering the permission', (
    tester,
  ) async {
    scanner
      ..result = const CardScanPermissionDenied(ImageSource.camera)
      ..gate = Completer<void>();
    await open(tester);
    await tester.tap(key('cardForm.scan'));
    await tester.pumpAndSettle();
    await tester.tap(key('cardForm.scan.camera'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(key('cardForm.scanning'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(key('cardForm.scan')).onPressed,
      isNull,
    );
    scanner.gate!.complete();
    await tester.pumpAndSettle();
    expect(key('cardForm.permissionDialog'), findsOneWidget);
  });

  testWidgets('denied gallery access asks for the photos, not the camera', (
    tester,
  ) async {
    scanner.result = const CardScanPermissionDenied(ImageSource.gallery);
    await open(tester);
    await scanFrom(tester, 'gallery');
    expect(find.text('Permite el acceso a tus fotos'), findsOneWidget);
    expect(find.textContaining('tomar una foto con la cámara'), findsOneWidget);
  });

  testWidgets('settings that cannot open show a hint instead of failing', (
    tester,
  ) async {
    scanner
      ..result = const CardScanPermissionDenied(ImageSource.camera)
      ..settingsError = Exception('MissingPluginException');
    await open(tester);
    await scanFrom(tester, 'camera');
    await tester.tap(key('cardForm.openSettings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('Abre los ajustes del teléfono para permitirlo'),
      findsOneWidget,
    );
  });

  testWidgets('a double tap opens a single source sheet', (tester) async {
    await open(tester);
    // Both taps land before the next frame. (The navigator already absorbs
    // the second one; _scan also guards against re-entry.)
    await tester.tap(key('cardForm.scan'));
    await tester.tap(key('cardForm.scan'));
    await tester.pumpAndSettle();
    expect(key('cardForm.scan.gallery'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    // Closing the sheet re-enables the button.
    expect(
      tester.widget<OutlinedButton>(key('cardForm.scan')).onPressed,
      isNotNull,
    );
  });

  testWidgets('opening a new card form discards lost photos', (tester) async {
    await open(tester);
    expect(scanner.lostDiscarded, 1);
  });

  testWidgets('a detected card without a known brand keeps the chosen one', (
    tester,
  ) async {
    scanner.result = const CardScanDetected(CardDetection(last4: '1117'));
    await open(tester);
    await tester.ensureVisible(key('cardForm.brand.amex'));
    await tester.tap(key('cardForm.brand.amex'));
    await tester.pump();
    await tester.ensureVisible(key('cardForm.scan'));
    await scanFrom(tester, 'gallery');
    expect(brandSelected(tester, CardBrand.amex), isTrue);
    expect(key('cardForm.detected.brand'), findsNothing);
  });

  testWidgets('an unexpected error shows the generic message', (tester) async {
    scanner.error = Exception('ML Kit');
    await open(tester);
    await scanFrom(tester, 'gallery');
    expect(find.text('Ocurrió un error. Intenta de nuevo.'), findsOneWidget);
    expect(key('cardForm.scanning'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(key('cardForm.scan')).onPressed,
      isNotNull,
    );
  });

  testWidgets('the scan button is not offered when editing', (tester) async {
    final card = await seedCard(db, userId);
    await open(tester, '/home/cards/${card.id}/edit');
    expect(key('cardForm.root'), findsOneWidget);
    expect(key('cardForm.scan'), findsNothing);
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
          await tester.ensureVisible(key('cardForm.scan'));
          await scanFrom(tester, 'gallery');
          expect(tester.takeException(), isNull);
          expect(key('cardForm.detected.bank'), findsOneWidget);
        });
      }

      testWidgets('source sheet: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        await open(tester);
        await tester.tap(key('cardForm.scan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(key('cardForm.scan.gallery'), findsOneWidget);
      });

      testWidgets('permission dialog: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        scanner.result = const CardScanPermissionDenied(ImageSource.camera);
        await open(tester);
        await scanFrom(tester, 'camera');
        expect(tester.takeException(), isNull);
        expect(key('cardForm.openSettings'), findsOneWidget);
      });

      testWidgets('loading overlay: ${c.name}', (tester) async {
        setScreen(tester, c.size, c.textScale);
        scanner.gate = Completer<void>();
        await open(tester);
        await tester.tap(key('cardForm.scan'));
        await tester.pumpAndSettle();
        await tester.tap(key('cardForm.scan.gallery'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(key('cardForm.scanning'), findsOneWidget);
        scanner.gate!.complete();
        await tester.pumpAndSettle();
      });
    }
  });
}
