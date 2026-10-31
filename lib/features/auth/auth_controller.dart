import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/language.dart';
import '../../core/money.dart';
import '../../core/security_question.dart';
import '../../data/models/app_user.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../services/app_prefs.dart';
import '../../services/providers.dart';

sealed class AuthState {
  const AuthState();
}

/// Opening the database / reading the saved session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No session. [biometricUser] is the last user, when they enabled
/// biometrics, so the login screen can offer fingerprint login.
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut({this.biometricUser});

  final AppUser? biometricUser;
}

/// A saved session that must be unlocked with biometrics.
class AuthNeedsUnlock extends AuthState {
  const AuthNeedsUnlock(this.user);

  final AppUser user;
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn(this.user);

  final AppUser user;
}

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  return AuthRepository(
    await ref.watch(appDatabaseProvider.future),
    ref.watch(passwordHasherProvider),
    ref.watch(loginThrottleProvider),
  );
}, retry: (retryCount, error) => null);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The app theme: the user's choice, or the last user's before login.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthLoggedIn(:final user) || AuthNeedsUnlock(:final user) => user.themeMode,
    _ => ref.watch(appPrefsProvider).lastThemeMode,
  };
});

/// The app language: the user's choice, or the last user's before login.
final languageProvider = Provider<AppLanguage>(
  (ref) => _languageFor(
    ref.watch(authControllerProvider),
    ref.watch(appPrefsProvider),
  ),
);

AppLanguage _languageFor(AuthState auth, AppPrefs prefs) => switch (auth) {
  AuthLoggedIn(:final user) || AuthNeedsUnlock(:final user) => user.language,
  _ => prefs.lastLanguage,
};

enum EnableBiometricsResult { enabled, unavailable, notConfirmed }

class AuthController extends Notifier<AuthState> {
  /// Texts in the app language, for the system biometric prompt. Same
  /// rule as [languageProvider], from this notifier's own state (reading
  /// that provider here would be a circular dependency).
  AppLocalizations get _l10n =>
      l10nFor(_languageFor(state, ref.read(appPrefsProvider)));

  @override
  AuthState build() {
    // Dates (`core/formatters.dart`) read the global Intl locale. Set it
    // the moment the session changes, before any screen rebuilds: a screen
    // that does not depend on the locale (Home, today) would otherwise
    // keep dates in the previous language.
    listenSelf((_, next) => _applyDateLocale(next));
    _applyDateLocale(const AuthLoading());
    _restoreSession();
    return const AuthLoading();
  }

  void _applyDateLocale(AuthState auth) =>
      Intl.defaultLocale = _languageFor(auth, ref.read(appPrefsProvider)).code;

  Future<AuthRepository> get _repo => ref.read(authRepositoryProvider.future);

  Future<void> _restoreSession() async {
    final AuthRepository repo;
    try {
      repo = await _repo;
    } on Object {
      // The splash shows the database error and its retry button.
      return;
    }
    try {
      state = await _savedSessionState(repo);
    } on Object {
      // Unreadable secure storage (e.g. keystore reset after a backup
      // restore): never get stuck on the splash, ask for the password.
      try {
        await ref.read(sessionServiceProvider).end();
      } on Object {
        // Nothing else to do; the login screen still works.
      }
      state = const AuthLoggedOut();
    }
  }

  Future<AuthState> _savedSessionState(AuthRepository repo) async {
    final session = ref.read(sessionServiceProvider);
    final userId = await session.currentUserId();
    final user = userId == null ? null : await repo.getById(userId);
    if (user == null) {
      if (userId != null) await session.end();
      return _loggedOut(repo);
    }
    if (!user.biometricEnabled) return AuthLoggedIn(user);
    if (await ref.read(biometricServiceProvider).isAvailable()) {
      return AuthNeedsUnlock(user);
    }
    // Biometrics were turned on but are gone (fingerprints removed): do not
    // skip authentication, fall back to the password.
    await session.end();
    return const AuthLoggedOut();
  }

  /// Throws the [AuthRepository.login] exceptions.
  Future<void> login(String email, String password) async {
    final user = await (await _repo).login(email, password);
    await _startSession(user);
  }

  /// Throws the [AuthRepository.register] exceptions.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required SecurityQuestion securityQuestion,
    required String securityAnswer,
  }) async {
    final user = await (await _repo).register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
      // The language the register screen was shown in.
      language: _languageFor(state, ref.read(appPrefsProvider)),
    );
    // Before the session starts, so the router goes straight to the wizard.
    await ref.read(setupPendingProvider.notifier).start(user.id!);
    await _startSession(user);
  }

  // ------------------------------------------------------ recovery (#27)
  // Before login: they never change the session; the user logs in after.

  /// Throws the [AuthRepository.securityQuestionFor] exceptions.
  Future<SecurityQuestion> securityQuestionFor(String email) async =>
      (await _repo).securityQuestionFor(email);

  /// Throws the [AuthRepository.checkSecurityAnswer] exceptions.
  Future<void> checkSecurityAnswer(String email, String answer) async =>
      (await _repo).checkSecurityAnswer(email, answer);

  /// Throws the [AuthRepository.resetPasswordWithAnswer] exceptions.
  Future<void> resetPasswordWithAnswer({
    required String email,
    required String answer,
    required String newPassword,
  }) async => (await _repo).resetPasswordWithAnswer(
    email: email,
    answer: answer,
    newPassword: newPassword,
  );

  /// Unlocks a saved session. Returns false if biometrics failed.
  Future<bool> unlock() async {
    final current = state;
    if (current is! AuthNeedsUnlock) return false;
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate(_l10n.biometricReasonUnlock);
    // The user may have chosen "Usar contraseña" while the prompt was open.
    if (!ok || !identical(state, current)) return false;
    _setUser(current.user);
    return true;
  }

  /// Fingerprint login for the last user after logging out.
  Future<bool> loginWithBiometrics() async {
    final current = state;
    if (current is! AuthLoggedOut || current.biometricUser == null) {
      return false;
    }
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate(_l10n.biometricReasonUnlock);
    if (!ok || !identical(state, current)) return false;
    final user = current.biometricUser!;
    // A verified fingerprint clears earlier password typos for this email.
    await ref.read(loginThrottleProvider).reset(user.email);
    await _startSession(user);
    return true;
  }

  /// From the unlock screen: drop the session and go to the password login.
  Future<void> usePassword() => logout();

  Future<void> logout() async {
    await ref.read(sessionServiceProvider).end();
    state = await _loggedOut(await _repo);
  }

  Future<void> _startSession(AppUser user) async {
    await ref.read(sessionServiceProvider).start(user.id!);
    _setUser(user);
  }

  /// The logged-in user after a change: every screen sees it at once.
  void _setUser(AppUser user) {
    state = AuthLoggedIn(user);
    ref.read(appPrefsProvider)
      ..setLastThemeMode(user.themeMode)
      ..setLastLanguage(user.language);
  }

  /// [user] after a profile edit, unless the session ended (logout) or
  /// changed while the edit was running.
  void _updateUser(AppUser user) {
    final current = state;
    if (current is AuthLoggedIn && current.user.id == user.id) _setUser(user);
  }

  AppUser get _user {
    final current = state;
    if (current is! AuthLoggedIn) throw StateError('Sin sesión');
    return current.user;
  }

  // ------------------------------------------------------------- profile

  /// Throws [ArgumentError].
  Future<void> updateName(String firstName, String lastName) async =>
      _updateUser(
        await (await _repo).updateName(_user.id!, firstName, lastName),
      );

  /// Throws the [AuthRepository.setSecurityQuestion] exceptions.
  Future<void> setSecurityQuestion({
    required String currentPassword,
    required SecurityQuestion question,
    required String answer,
  }) async => _updateUser(
    await (await _repo).setSecurityQuestion(
      _user.id!,
      currentPassword: currentPassword,
      question: question,
      answer: answer,
    ),
  );

  /// Throws the [AuthRepository.changeEmail] exceptions.
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async => _updateUser(
    await (await _repo).changeEmail(
      _user.id!,
      currentPassword: currentPassword,
      newEmail: newEmail,
    ),
  );

  /// Throws the [AuthRepository.changePassword] exceptions.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => _updateUser(
    await (await _repo).changePassword(
      _user.id!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  Future<void> updatePreferences({
    ThemeMode? themeMode,
    Currency? defaultCurrency,
    int? notifyDaysBefore,
    AppLanguage? language,
  }) async => _updateUser(
    await (await _repo).updatePreferences(
      _user.id!,
      themeMode: themeMode,
      defaultCurrency: defaultCurrency,
      notifyDaysBefore: notifyDaysBefore,
      language: language,
    ),
  );

  /// Turns biometrics on only after a verified fingerprint.
  Future<EnableBiometricsResult> enableBiometrics() async {
    // Taken now: the prompt can stay open while the session changes.
    final userId = _user.id!;
    final bio = ref.read(biometricServiceProvider);
    if (!await bio.isAvailable()) return EnableBiometricsResult.unavailable;
    if (!await bio.authenticate(_l10n.biometricReasonEnable)) {
      return EnableBiometricsResult.notConfirmed;
    }
    _updateUser(
      await (await _repo).updatePreferences(userId, biometricEnabled: true),
    );
    return EnableBiometricsResult.enabled;
  }

  Future<void> disableBiometrics() async => _updateUser(
    await (await _repo).updatePreferences(_user.id!, biometricEnabled: false),
  );

  Future<AuthLoggedOut> _loggedOut(AuthRepository repo) async {
    final lastId = await ref.read(sessionServiceProvider).lastUserId();
    final last = lastId == null ? null : await repo.getById(lastId);
    final offerBiometrics =
        last != null &&
        last.biometricEnabled &&
        await ref.read(biometricServiceProvider).isAvailable();
    return AuthLoggedOut(biometricUser: offerBiometrics ? last : null);
  }
}
