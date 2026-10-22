import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_prefs.dart';
import 'biometric_service.dart';
import 'login_throttle.dart';
import 'password_hasher.dart';
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
