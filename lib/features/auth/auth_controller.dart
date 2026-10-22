import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
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

class AuthController extends Notifier<AuthState> {
  static const biometricReason = 'Confirma tu identidad para entrar';

  @override
  AuthState build() {
    _restoreSession();
    return const AuthLoading();
  }

  Future<AuthRepository> get _repo => ref.read(authRepositoryProvider.future);

  Future<void> _restoreSession() async {
    final AuthRepository repo;
    try {
      repo = await _repo;
    } on Object {
      // The splash shows the database error and its retry button.
      return;
    }
    final session = ref.read(sessionServiceProvider);
    final userId = await session.currentUserId();
    final user = userId == null ? null : await repo.getById(userId);
    if (user == null) {
      if (userId != null) await session.end();
      state = await _loggedOut(repo);
      return;
    }
    final mustUnlock =
        user.biometricEnabled &&
        await ref.read(biometricServiceProvider).isAvailable();
    state = mustUnlock ? AuthNeedsUnlock(user) : AuthLoggedIn(user);
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
  }) async {
    final user = await (await _repo).register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    await _startSession(user);
  }

  /// Unlocks a saved session. Returns false if biometrics failed.
  Future<bool> unlock() async {
    final current = state;
    if (current is! AuthNeedsUnlock) return false;
    if (!await ref
        .read(biometricServiceProvider)
        .authenticate(biometricReason)) {
      return false;
    }
    state = AuthLoggedIn(current.user);
    return true;
  }

  /// Fingerprint login for the last user after logging out.
  Future<bool> loginWithBiometrics() async {
    final current = state;
    if (current is! AuthLoggedOut || current.biometricUser == null) {
      return false;
    }
    if (!await ref
        .read(biometricServiceProvider)
        .authenticate(biometricReason)) {
      return false;
    }
    await _startSession(current.biometricUser!);
    return true;
  }

  /// From the unlock screen: drop the session and go to the password login.
  Future<void> usePassword() async {
    await ref.read(sessionServiceProvider).end();
    state = await _loggedOut(await _repo);
  }

  Future<void> logout() async {
    await ref.read(sessionServiceProvider).end();
    state = await _loggedOut(await _repo);
  }

  Future<void> _startSession(AppUser user) async {
    await ref.read(sessionServiceProvider).start(user.id!);
    state = AuthLoggedIn(user);
  }

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
