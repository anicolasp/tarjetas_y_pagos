import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarjetas_y_pagos/app.dart';
import 'package:tarjetas_y_pagos/data/database.dart';
import 'package:tarjetas_y_pagos/data/providers.dart';
import 'package:tarjetas_y_pagos/services/biometric_service.dart';
import 'package:tarjetas_y_pagos/services/password_hasher.dart';
import 'package:tarjetas_y_pagos/services/providers.dart';
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

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return available && succeeds;
  }
}

/// Overrides every platform-backed provider with an in-memory fake.
Future<List<Override>> testOverrides({
  Future<AppDatabase>? database,
  Map<String, Object> prefs = const {},
  InMemorySecureStore? secureStore,
  FakeBiometricService? biometrics,
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
  ];
}

Widget testApp(List<Override> overrides) =>
    ProviderScope(overrides: overrides, child: const TarjetasApp());
