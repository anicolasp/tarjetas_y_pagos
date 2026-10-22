import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/unlock_screen.dart';
import '../features/home/home_placeholder_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../services/providers.dart';

abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const unlock = '/unlock';
  static const home = '/home';
}

const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
  Routes.register,
  Routes.unlock,
};

/// Where the user must be for the current auth/onboarding state, or null to
/// stay on [location].
@visibleForTesting
String? authRedirect({
  required AuthState auth,
  required bool onboardingSeen,
  required String location,
}) {
  String? goTo(String target) => location == target ? null : target;

  // Onboarding comes first, but only once we know the auth state.
  if (!onboardingSeen && auth is! AuthLoading) return goTo(Routes.onboarding);
  return switch (auth) {
    AuthLoading() => goTo(Routes.splash),
    AuthNeedsUnlock() => goTo(Routes.unlock),
    AuthLoggedOut() =>
      location == Routes.login || location == Routes.register
          ? null
          : Routes.login,
    AuthLoggedIn() => _publicRoutes.contains(location) ? Routes.home : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever the session or onboarding flag changes.
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      auth: ref.read(authControllerProvider),
      onboardingSeen: ref.read(onboardingSeenProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.unlock,
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
