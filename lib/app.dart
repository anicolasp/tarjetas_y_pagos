import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return MaterialApp.router(
      title: 'Tarjetas y Pagos',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
