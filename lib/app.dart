import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final language = ref.watch(languageProvider);
    // Dates (`core/formatters.dart`) read it; set before the tree builds.
    Intl.defaultLocale = language.code;
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
