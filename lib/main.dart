import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/formatters.dart';
import 'services/providers.dart';

Future<void> main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  Intl.defaultLocale = appLocale;
  // Every supported language: the user can switch at any time.
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  final app = ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TarjetasApp(),
  );
  // Lets Marionette override theme and text scale during visual checks.
  // Same condition as MarionetteBinding above, so profile builds stay clean.
  runApp(kDebugMode ? MarionetteDeviceConfig(child: app) : app);
}
