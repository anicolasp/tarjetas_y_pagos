import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive app flags.
class AppPrefs {
  const AppPrefs(this._prefs);

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _lastThemeKey = 'last_theme_mode';

  final SharedPreferences _prefs;

  bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;

  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeenKey, true);

  /// The theme of the last user, for the screens before login (splash,
  /// login, unlock) so they don't flash in another theme.
  ThemeMode get lastThemeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_lastThemeKey),
    orElse: () => ThemeMode.system,
  );

  Future<void> setLastThemeMode(ThemeMode mode) =>
      _prefs.setString(_lastThemeKey, mode.name);
}
