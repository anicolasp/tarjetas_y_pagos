import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database. The schema evolves through [_migrations]: index 0
/// upgrades to version 1, index 1 to version 2, and so on. New installs run
/// every migration in order, so there is a single source of truth.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'tarjetas_y_pagos.db';
  static int get version => _migrations.length;

  /// Opens (and creates or upgrades) the database. Tests pass
  /// `databaseFactoryFfi` and `inMemoryDatabasePath`.
  ///
  /// [targetVersion] opens an older schema; only for migration tests.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    @visibleForTesting int? targetVersion,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: targetVersion ?? version,
        // SQLite ignores foreign keys unless enabled on every connection.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from; v < to; v++) {
      await _migrations[v](db);
    }
  }
}

typedef _Migration = Future<void> Function(Database db);

final List<_Migration> _migrations = [_v1, _v2, _v3, _v4];

/// Base categories available to every user (`user_id IS NULL`).
/// `icon` is a key resolved to a Material icon by the UI layer.
const baseCategories = <({String name, String icon, int color})>[
  (name: 'Supermercado', icon: 'shopping_cart', color: 0xFF2E7D32),
  (name: 'Combustible', icon: 'local_gas_station', color: 0xFFEF6C00),
  (name: 'Barbería', icon: 'content_cut', color: 0xFF5D4037),
  (name: 'Salón', icon: 'face_retouching_natural', color: 0xFFAD1457),
  (name: 'Belleza', icon: 'spa', color: 0xFFD81B60),
  (name: 'Ferretería', icon: 'hardware', color: 0xFF546E7A),
  (name: 'Luz', icon: 'bolt', color: 0xFFF9A825),
  (name: 'Agua', icon: 'water_drop', color: 0xFF0277BD),
  (name: 'Teléfono', icon: 'phone_android', color: 0xFF3949AB),
  (name: 'Licor', icon: 'liquor', color: 0xFF6A1B9A),
  (name: 'Salud', icon: 'medical_services', color: 0xFFC62828),
  (name: 'Restaurante', icon: 'restaurant', color: 0xFF00897B),
  (name: 'Otros', icon: 'category', color: 0xFF757575),
];

Future<void> _v1(Database db) async {
  final batch = db.batch();
  batch.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      biometric_enabled INTEGER NOT NULL DEFAULT 0,
      theme_mode TEXT NOT NULL DEFAULT 'system'
        CHECK (theme_mode IN ('system', 'light', 'dark')),
      default_currency TEXT NOT NULL DEFAULT 'DOP'
        CHECK (default_currency IN ('DOP', 'USD')),
      notify_days_before INTEGER NOT NULL DEFAULT 3,
      created_at TEXT NOT NULL
    )''');
  batch.execute('''
    CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      alias TEXT NOT NULL,
      bank TEXT NOT NULL,
      brand TEXT NOT NULL CHECK (brand IN ('visa', 'mastercard', 'amex', 'otra')),
      last4 TEXT NOT NULL CHECK (length(last4) = 4 AND last4 NOT GLOB '*[^0-9]*'),
      cut_day INTEGER NOT NULL CHECK (cut_day BETWEEN 1 AND 31),
      payment_days INTEGER NOT NULL DEFAULT 20 CHECK (payment_days BETWEEN 0 AND 60),
      credit_limit_cents INTEGER NOT NULL DEFAULT 0 CHECK (credit_limit_cents >= 0),
      currency TEXT NOT NULL CHECK (currency IN ('DOP', 'USD')),
      color INTEGER NOT NULL,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      -- Target of the composite FK in expenses (card must belong to the user).
      UNIQUE (id, user_id)
    )''');
  batch.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      icon TEXT NOT NULL,
      color INTEGER NOT NULL
    )''');
  batch.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      card_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
      merchant TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
      currency TEXT NOT NULL CHECK (currency IN ('DOP', 'USD')),
      date TEXT NOT NULL,
      notes TEXT,
      source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'ia')),
      created_at TEXT NOT NULL,
      FOREIGN KEY (card_id, user_id) REFERENCES cards(id, user_id)
        ON DELETE CASCADE
    )''');
  batch.execute('''
    CREATE TABLE card_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
      amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
      currency TEXT NOT NULL CHECK (currency IN ('DOP', 'USD')),
      date TEXT NOT NULL,
      note TEXT
    )''');
  batch.execute('''
    CREATE TABLE debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      creditor TEXT NOT NULL,
      description TEXT,
      amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
      currency TEXT NOT NULL CHECK (currency IN ('DOP', 'USD')),
      due_date TEXT,
      status TEXT NOT NULL DEFAULT 'activa' CHECK (status IN ('activa', 'saldada')),
      created_at TEXT NOT NULL
    )''');
  batch.execute('''
    CREATE TABLE debt_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      debt_id INTEGER NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
      amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
      date TEXT NOT NULL,
      note TEXT
    )''');

  batch.execute('CREATE INDEX idx_cards_user ON cards(user_id)');
  batch.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
  // One name per owner; base categories (NULL owner) are grouped as 0.
  batch.execute(
    'CREATE UNIQUE INDEX idx_categories_owner_name '
    'ON categories(IFNULL(user_id, 0), name COLLATE NOCASE)',
  );
  batch.execute(
    'CREATE INDEX idx_expenses_user_card_date ON expenses(user_id, card_id, date)',
  );
  batch.execute(
    'CREATE INDEX idx_expenses_user_date ON expenses(user_id, date)',
  );
  batch.execute(
    'CREATE INDEX idx_card_payments_card ON card_payments(card_id)',
  );
  batch.execute('CREATE INDEX idx_debts_user ON debts(user_id)');
  batch.execute(
    'CREATE INDEX idx_debt_payments_debt ON debt_payments(debt_id)',
  );

  for (final c in baseCategories) {
    batch.insert('categories', {
      'user_id': null,
      'name': c.name,
      'icon': c.icon,
      'color': c.color,
    });
  }
  await batch.commit(noResult: true);
}

/// v2 (#5): dual-currency cards and currency conversion on expenses.
Future<void> _v2(Database db) async {
  final batch = db.batch();
  // A dual card has balances in DOP (its `currency`) and USD; the USD limit
  // is `secondary_limit_cents`.
  batch.execute(
    'ALTER TABLE cards ADD COLUMN dual_currency INTEGER NOT NULL DEFAULT 0',
  );
  batch.execute(
    'ALTER TABLE cards ADD COLUMN secondary_limit_cents INTEGER NOT NULL '
    'DEFAULT 0 CHECK (secondary_limit_cents >= 0)',
  );
  // Set only when an expense was converted to the card currency: what was
  // typed and the rate used, always as RD$ per US$ x 1,000,000.
  batch.execute(
    'ALTER TABLE expenses ADD COLUMN original_amount_cents INTEGER '
    'CHECK (original_amount_cents IS NULL OR original_amount_cents > 0)',
  );
  batch.execute(
    "ALTER TABLE expenses ADD COLUMN original_currency TEXT "
    "CHECK (original_currency IS NULL OR original_currency IN ('DOP', 'USD'))",
  );
  batch.execute(
    'ALTER TABLE expenses ADD COLUMN exchange_rate_micros INTEGER '
    'CHECK (exchange_rate_micros IS NULL OR exchange_rate_micros > 0)',
  );
  batch.execute(
    'CREATE INDEX idx_card_payments_card_date ON card_payments(card_id, date)',
  );
  await batch.commit(noResult: true);
}

/// v3 (#26): the user's language. Existing users stay in Spanish. No CHECK
/// on the codes: adding a language must not need a table rebuild, and an
/// unknown code is read as Spanish (`AppLanguage.fromCode`).
Future<void> _v3(Database db) async {
  await db.execute(
    "ALTER TABLE users ADD COLUMN language TEXT NOT NULL DEFAULT 'es'",
  );
}

/// v4 (#27): security question for password recovery. NULL for accounts
/// created before it (they are asked to set one in Mi perfil). The answer
/// is stored only as a PBKDF2 hash with its own salt.
Future<void> _v4(Database db) async {
  final batch = db.batch();
  batch.execute('ALTER TABLE users ADD COLUMN security_question TEXT');
  batch.execute('ALTER TABLE users ADD COLUMN security_answer_hash TEXT');
  batch.execute('ALTER TABLE users ADD COLUMN security_salt TEXT');
  await batch.commit(noResult: true);
}
