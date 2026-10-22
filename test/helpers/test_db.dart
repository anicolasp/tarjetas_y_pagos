import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarjetas_y_pagos/data/database.dart';

/// Fresh in-memory database per call, backed by sqflite FFI.
Future<AppDatabase> openTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.open(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
}
