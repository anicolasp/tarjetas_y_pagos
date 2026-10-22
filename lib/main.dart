import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'app.dart';
import 'core/formatters.dart';

Future<void> main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  Intl.defaultLocale = appLocale;
  await initializeDateFormatting(appLocale);
  const app = ProviderScope(child: TarjetasApp());
  // Lets Marionette override theme and text scale during visual checks.
  // Same condition as MarionetteBinding above, so profile builds stay clean.
  runApp(kDebugMode ? const MarionetteDeviceConfig(child: app) : app);
}
