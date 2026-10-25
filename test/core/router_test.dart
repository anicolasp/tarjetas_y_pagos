import 'package:flutter_test/flutter_test.dart';
import 'package:tarjetas_y_pagos/core/router.dart';
import 'package:tarjetas_y_pagos/data/models/app_user.dart';
import 'package:tarjetas_y_pagos/features/auth/auth_controller.dart';

void main() {
  final user = AppUser(
    id: 1,
    firstName: 'Ana',
    lastName: 'Prueba',
    email: 'ana@example.com',
    passwordHash: 'h',
    salt: 's',
    createdAt: DateTime(2026),
  );

  String? go(AuthState auth, String location, {bool seen = true}) =>
      authRedirect(auth: auth, onboardingSeen: seen, location: location);

  test('loading always shows the splash', () {
    expect(go(const AuthLoading(), Routes.login), Routes.splash);
    expect(go(const AuthLoading(), Routes.splash), isNull);
  });

  test('first launch shows onboarding before anything else', () {
    expect(
      go(const AuthLoggedOut(), Routes.splash, seen: false),
      Routes.onboarding,
    );
    expect(go(AuthLoggedIn(user), Routes.home, seen: false), Routes.onboarding);
    expect(go(const AuthLoggedOut(), Routes.onboarding, seen: false), isNull);
  });

  test('logged out can only be on login or register', () {
    expect(go(const AuthLoggedOut(), Routes.splash), Routes.login);
    expect(go(const AuthLoggedOut(), Routes.home), Routes.login);
    expect(go(const AuthLoggedOut(), Routes.login), isNull);
    expect(go(const AuthLoggedOut(), Routes.register), isNull);
  });

  test('a locked session must unlock first', () {
    expect(go(AuthNeedsUnlock(user), Routes.home), Routes.unlock);
    expect(go(AuthNeedsUnlock(user), Routes.unlock), isNull);
  });

  test('logged in leaves the auth screens for home', () {
    for (final r in [
      Routes.splash,
      Routes.onboarding,
      Routes.login,
      Routes.register,
      Routes.unlock,
    ]) {
      expect(go(AuthLoggedIn(user), r), Routes.home, reason: r);
    }
    expect(go(AuthLoggedIn(user), Routes.home), isNull);
  });

  test('setup pending: Home and public routes lead to the wizard', () {
    String? pending(String location) => authRedirect(
      auth: AuthLoggedIn(user),
      onboardingSeen: true,
      location: location,
      setupPending: true,
    );
    expect(pending(Routes.home), Routes.setup);
    expect(pending(Routes.register), Routes.setup);
    expect(pending(Routes.setup), isNull);
    // The card form opened from the wizard stays open.
    expect(pending(Routes.cardNew), isNull);
  });

  test('without setup pending the wizard is not reachable', () {
    expect(go(AuthLoggedIn(user), Routes.setup), Routes.home);
    expect(go(const AuthLoggedOut(), Routes.setup), Routes.login);
  });
}
