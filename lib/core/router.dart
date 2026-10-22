import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
}

/// App router. Session and onboarding redirects are added with the auth
/// flow (#2).
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
