import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive app flags.
class AppPrefs {
  const AppPrefs(this._prefs);

  static const _onboardingSeenKey = 'onboarding_seen';

  final SharedPreferences _prefs;

  bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;

  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeenKey, true);
}
