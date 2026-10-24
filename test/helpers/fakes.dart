import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/app.dart';
import 'package:tarjetas_y_pagos/core/clock.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/providers.dart';
import 'package:tarjetas_y_pagos/features/cards/cards_providers.dart';
import 'package:tarjetas_y_pagos/services/exchange_rate_service.dart';
import 'package:tarjetas_y_pagos/services/biometric_service.dart';
import 'package:tarjetas_y_pagos/services/card_scan_service.dart';
import 'package:tarjetas_y_pagos/services/password_hasher.dart';
import 'package:tarjetas_y_pagos/data/models/category.dart';
import 'package:tarjetas_y_pagos/services/providers.dart';
import 'package:tarjetas_y_pagos/services/receipt_ai_service.dart';
import 'package:tarjetas_y_pagos/services/session_service.dart';

/// Low iteration count and no isolate, so tests are fast and run under the
/// widget tester's fake async.
const testHasher = PasswordHasher(iterations: 1000, useIsolate: false);

class InMemorySecureStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;
  var prompts = 0;

  /// When set, the prompt stays open until the test completes it.
  Completer<bool>? pending;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    if (pending != null) return pending!.future;
    return available && succeeds;
  }
}

/// Fixed US$→RD$ rate (61.409228); null simulates being offline.
class FakeRateSource implements ExchangeRateSource {
  FakeRateSource([this.micros = 61409228]);

  int? micros;
  var calls = 0;

  @override
  Future<int> fetchUsdToDopMicros() async {
    calls++;
    if (micros == null) throw Exception('sin internet');
    return micros!;
  }
}

/// Returns [result] (default: nothing read) and records the sources used.
class FakeCardScanService implements CardScanService {
  FakeCardScanService([this.result = const CardScanNothing()]);

  CardScanResult result;
  final sources = <ImageSource>[];
  var settingsOpened = 0;
  var lostDiscarded = 0;

  /// Thrown by [openSettings] when set.
  Object? settingsError;

  /// Completes the scan when set; lets a test see the loading overlay.
  Completer<void>? gate;

  /// Thrown by [scan] when set.
  Object? error;

  @override
  Future<CardScanResult> scan(
    ImageSource source, {
    void Function()? onReading,
  }) async {
    sources.add(source);
    if (result is CardScanDetected || result is CardScanNothing) {
      onReading?.call();
    }
    await gate?.future;
    if (error case final e?) throw e;
    return result;
  }

  @override
  Future<void> openSettings() async {
    if (settingsError case final e?) throw e;
    settingsOpened++;
  }

  @override
  Future<void> discardLostPhotos() async => lostDiscarded++;
}

/// Returns [result] and records what the form sent. Never calls the API.
class FakeReceiptAiService implements ReceiptAiService {
  FakeReceiptAiService([
    this.result = const ReceiptScanFailed(ReceiptScanError.invalidResponse),
  ]);

  ReceiptScanResult result;
  final sources = <ImageSource>[];
  List<Category>? categories;
  var settingsOpened = 0;
  var lostDiscarded = 0;

  /// Completes the scan when set; lets a test see the loading overlay.
  Completer<void>? gate;

  @override
  Future<ReceiptScanResult> scan(
    ImageSource source, {
    required List<Category> categories,
    required DateTime today,
    void Function()? onReading,
  }) async {
    sources.add(source);
    this.categories = categories;
    if (result is ReceiptScanRead || result is ReceiptScanFailed) {
      onReading?.call();
    }
    await gate?.future;
    return result;
  }

  @override
  Future<void> discardLostPhotos() async => lostDiscarded++;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// Secure storage whose reads fail, like a reset Android keystore.
class BrokenSecureStore extends InMemorySecureStore {
  @override
  Future<String?> read(String key) async =>
      throw Exception('keystore unavailable');
}

/// Overrides every platform-backed provider with an in-memory fake.
Future<List<Override>> testOverrides({
  Future<AppDatabase>? database,
  Map<String, Object> prefs = const {},
  InMemorySecureStore? secureStore,
  FakeBiometricService? biometrics,
  DateTime? now,
  FakeRateSource? rates,
  FakeCardScanService? cardScan,
  String anthropicApiKey = '',
  FakeReceiptAiService? receiptAi,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    secureStoreProvider.overrideWithValue(secureStore ?? InMemorySecureStore()),
    biometricServiceProvider.overrideWithValue(
      biometrics ?? FakeBiometricService(available: false),
    ),
    passwordHasherProvider.overrideWithValue(testHasher),
    if (database != null) appDatabaseProvider.overrideWith((ref) => database),
    if (now != null) clockProvider.overrideWithValue(() => now),
    // Never hit the network from tests.
    exchangeRateSourceProvider.overrideWithValue(rates ?? FakeRateSource()),
    // Never open the camera or ML Kit from tests.
    cardScanServiceProvider.overrideWithValue(
      cardScan ?? FakeCardScanService(),
    ),
    // No key by default (the scan button is hidden) and never the real API.
    anthropicApiKeyProvider.overrideWithValue(anthropicApiKey),
    receiptAiServiceProvider.overrideWithValue(
      receiptAi ?? FakeReceiptAiService(),
    ),
  ];
}

Widget testApp(List<Override> overrides) =>
    ProviderScope(overrides: overrides, child: const TarjetasApp());
