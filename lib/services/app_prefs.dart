import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/language.dart';

/// Non-sensitive app flags.
class AppPrefs {
  const AppPrefs(this._prefs);

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _lastThemeKey = 'last_theme_mode';
  static const _setupPendingKey = 'setup_pending_user';
  static const _lastLanguageKey = 'last_language';

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

  /// The language of the last user, for the screens before login.
  AppLanguage get lastLanguage =>
      AppLanguage.fromCode(_prefs.getString(_lastLanguageKey));

  Future<void> setLastLanguage(AppLanguage language) =>
      _prefs.setString(_lastLanguageKey, language.code);

  /// The user who registered and has not finished (or skipped) the setup
  /// wizard yet.
  int? get setupPendingUser => _prefs.getInt(_setupPendingKey);

  Future<void> setSetupPendingUser(int? userId) => userId == null
      ? _prefs.remove(_setupPendingKey)
      : _prefs.setInt(_setupPendingKey, userId);
}
