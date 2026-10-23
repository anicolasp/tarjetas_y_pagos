import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/unlock_screen.dart';
import '../features/cards/card_detail_screen.dart';
import '../features/cards/card_form_screen.dart';
import '../features/cards/cards_screen.dart';
import '../features/cards/payment_form_screen.dart';
import '../features/expenses/expense_form_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_placeholder_screen.dart';
import '../features/splash/splash_screen.dart';
import '../services/providers.dart';

abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const unlock = '/unlock';
  static const home = '/home';

  // Private screens live under /home so `go` always keeps Home below them
  // and the Android back button never closes the app from a sub-screen.
  static const profile = '/home/profile';
  static const cards = '/home/cards';
  static const cardNew = '/home/cards/new';
  static String cardDetail(int id) => '/home/cards/$id';
  static String cardEdit(int id) => '/home/cards/$id/edit';
  static String cardPay(int id) => '/home/cards/$id/pay';

  /// New expense, optionally with the card preselected.
  static String expenseNew({int? cardId}) =>
      '/home/expenses/new${cardId == null ? '' : '?cardId=$cardId'}';
  static String expenseEdit(int id) => '/home/expenses/$id';
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
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePlaceholderScreen(),
          ),
          GoRoute(
            path: 'cards',
            builder: (context, state) => const CardsScreen(),
            routes: [
              // 'new' must come before ':id'.
              GoRoute(
                path: 'new',
                builder: (context, state) => const CardFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    CardDetailScreen(cardId: _cardId(state)),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        CardFormScreen(cardId: _cardId(state)),
                  ),
                  GoRoute(
                    path: 'pay',
                    builder: (context, state) =>
                        PaymentFormScreen(cardId: _cardId(state)),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'expenses/new',
            builder: (context, state) => ExpenseFormScreen(
              initialCardId: int.tryParse(
                state.uri.queryParameters['cardId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'expenses/:id',
            builder: (context, state) =>
                ExpenseFormScreen(expenseId: _cardId(state)),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Id from the path; an invalid id (-1) shows "not found".
int _cardId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
