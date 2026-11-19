import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/accessibility.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/notifications/reminders.dart';
import 'l10n/l10n.dart';

class TarjetasApp extends ConsumerWidget {
  const TarjetasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(remindersProvider);
    // The date locale (Intl.defaultLocale) is kept in step by the
    // AuthController, before any screen rebuilds.
    final language = ref.watch(languageProvider);
    final a11y = ref.watch(a11yProvider);
    return MaterialApp.router(
      title: 'Tarjetas y Pagos',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light, a11y),
      darkTheme: _theme(Brightness.dark, a11y),
      // The phone's own high-contrast setting picks these (#38).
      highContrastTheme: _theme(Brightness.light, a11y, highContrast: true),
      highContrastDarkTheme: _theme(Brightness.dark, a11y, highContrast: true),
      themeMode: ref.watch(themeModeProvider),
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          A11yMediaQuery(settings: a11y, child: child!),
    );
  }
}

/// Built once per combination: a new [ThemeData] on every rebuild would
/// restart the theme animation.
final _themes = <(Brightness, bool, bool), ThemeData>{};

ThemeData _theme(
  Brightness brightness,
  A11ySettings a11y, {
  bool highContrast = false,
}) {
  final key = (brightness, highContrast || a11y.highContrast, a11y.legibleFont);
  return _themes[key] ??= buildTheme(
    brightness,
    highContrast: key.$2,
    legibleFont: key.$3,
  );
}
