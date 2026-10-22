import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// The opened app database. Override in tests with an in-memory instance.
///
/// Automatic retry is off: a failure is shown right away and the splash
/// offers a manual "Reintentar".
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}, retry: (retryCount, error) => null);
