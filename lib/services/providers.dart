import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_prefs.dart';
import 'biometric_service.dart';
import 'card_scan_service.dart';
import 'login_throttle.dart';
import 'password_hasher.dart';
import 'receipt_ai_service.dart';
import 'session_service.dart';

/// Loaded in `main()` before `runApp` and injected with `overrideWithValue`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final appPrefsProvider = Provider<AppPrefs>(
  (ref) => AppPrefs(ref.watch(sharedPreferencesProvider)),
);

final passwordHasherProvider = Provider<PasswordHasher>(
  (ref) => const PasswordHasher(),
);

final loginThrottleProvider = Provider<LoginThrottle>(
  (ref) => LoginThrottle(ref.watch(sharedPreferencesProvider)),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(ref.watch(secureStoreProvider)),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

final cardScanServiceProvider = Provider<CardScanService>(
  (ref) => MlKitCardScanService(),
);

/// Passed at build time (`--dart-define-from-file`); empty hides the
/// receipt scan. Never logged or shown.
final anthropicApiKeyProvider = Provider<String>(
  (ref) => const String.fromEnvironment('ANTHROPIC_API_KEY'),
);

final receiptAiServiceProvider = Provider<ReceiptAiService>(
  (ref) => ClaudeReceiptService(ref.watch(anthropicApiKeyProvider)),
);

/// Whether the welcome slides were already shown on this device.
final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(
  OnboardingSeen.new,
);

class OnboardingSeen extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPrefsProvider).onboardingSeen;

  Future<void> complete() async {
    await ref.read(appPrefsProvider).setOnboardingSeen();
    state = true;
  }
}
